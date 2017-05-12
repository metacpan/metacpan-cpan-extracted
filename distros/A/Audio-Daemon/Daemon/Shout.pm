package Audio::Daemon::Shout;

use strict;
use IO::Socket;
use IO::Select;
use Audio::Daemon;
use Shout;
use MP3::Info;

use vars qw(@ISA $VERSION);

@ISA = qw(Audio::Daemon);
$VERSION='0.99Beta';

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  # initilize current playlist
  $self->{playlist} = [];
  # initialize random index.
  $self->{random} = [];
  $self->{revrandom} = [];
  # initilize my current states of various things
  $self->{state} = {random => 0, repeat => 0, state => 0};
  $self->connect;
  return $self;
}

sub connect {
  my $self = shift;
  my $config = $self->{Pass};
  my %params;
  # can also set 'lame' parameter, 
  # checked for to see if we downsample when streaming.
  foreach my $p (qw/ip port mount password icy_compat aim icq irc
                dumpfile name url genre description bitrate ispublic/) {
    if (defined $self->{Pass}{$p}) {
      $self->debug("Setting $p to \"".$config->{$p}."\"");
      $params{$p} = $config->{$p};
    }
  }
  my $server = new Shout(%params);
  if (! defined $server) {
    $self->crit("Failed to initialize Should object: $!");
    return;
  }
  if (! $server->connect) {
    $self->crit("Failed to connect to server: ".$server->error);
    return;
  }
  $self->player($server);
}

sub player {
  my $self = shift;
  $self->{player} = shift if (scalar @_);
  return $self->{player};
}

sub stop {
  my $self = shift;
  $self->{state}{state} = 0;
}
  
sub play {
  my $self = shift;
  my $remote = shift;
  my $player = $self->player;
  if (defined $remote && ref $remote && scalar @{$remote->{args}}) {
    if ($self->{state}{random}) {
      $self->{state}{renid} = $self->{revrandom}[$remote->{args}[0]];
      $self->{state}{regid} = $remote->{args}[0];
    }
  }
  $self->debug("Random is ".($self->{state}{random})?'true':'false');
  my $id = $self->{state}{regid};
  $self->info("Setting current playlist id to $id and song to ".$self->{playlist}[$id]);
  if (! -r $self->{playlist}[$id]) {
    $self->crit("File Not Found or Not Readable: ".$self->{playlist}[$id]);
    return;
  }
  $self->{state}{state} = 2;
}

sub pause {
  my $self = shift;
  $self->{state}{state} = 1 if ($self->{state}{state} == 2);
  $self->{state}{state} = 2 if ($self->{state}{state} == 1);
}

sub add {
  my $self = shift;
  my $remote = shift;
  push @{$self->{playlist}}, @{$remote->{args}};
  # create array of indexes: 
  my @trandom = map { $_ } (0..$#{$self->{playlist}});
  $self->randomize(\@trandom);
  # if we have a "new" list, start playing otherwise continue on
  if (scalar @{$self->{playlist}} == scalar @{$remote->{args}}) {
    if ($self->{state}{random}) {
      $self->{state}{ranid} = 0;
      $self->{state}{regid} = $self->{random}[0];
    } else {
      $self->{state}{regid} = 0;
      $self->{state}{ranid} = $self->{revrandom}[0];
    }
    # $self->debug("Setting regid to ".$self->{state}{regid}." and ranid to ".$self->{state}{ranid});
    $self->play;
  }
}

sub del {
  my $self = shift;
  my $remote = shift;
  if ($remote->{args}[0] eq 'all') {
    $self->{playlist} = [];
    $self->{state}{state} = 0;
  } elsif (scalar @{$remote->{args}}) {
    my @args = sort { $b <=> $a } @{$remote->{args}};
    foreach my $index (@args) {
      splice(@{$self->{playlist}}, $index, 1);
    }
    my @trandom = map { $_ } (0..$#{$self->{playlist}});
    $self->randomize(\@trandom);
    if (scalar grep {/^$self->{state}{regid}$/} @args) {
      $self->next;
    }
  }
}

sub next {
  my $self = shift;
  my $remote = shift;
  # $self->debug("Random and repeat: ".$self->{state}{random}."/".$self->{state}{repeat});

  my $callplay = 0;
  my $id;
  if ($self->{state}{random}) {
    # $self->debug("Taking random ID ".$self->{state}{ranid}." to move forward on");
    $id = $self->{state}{ranid};
  } else {
    # $self->debug("Taking straight ID ".$self->{state}{regid}." to move forward on");
    $id = $self->{state}{regid};
  }
  $id++;
  if ($id > $#{$self->{playlist}}) {
    # $self->debug("end of playlist found");
    $id = 0;
    if ((ref $remote && $remote->{cmd} eq 'next') || $self->{state}{repeat}) {
      $callplay = 1 if ($self->{state}{state} != 0);
    }
  } else {
    $callplay = 1 if ($self->{state}{state} != 0);
  }
  if ($self->{state}{random}) {
    # $self->debug("assigning $id back to random ID");
    $self->{state}{ranid} = $id;
    $self->{state}{regid} = $self->{random}[$id];
  } else {
    # $self->debug("assigning $id back to regular ID");
    $self->{state}{regid} = $id;
    $self->{state}{ranid} = $self->{revrandom}[$id];
  }
  if ($callplay) {
    $self->closefile;
    $self->initfile;
  }
}

sub prev {
  my $self = shift;
  my $remote = shift;
  # $self->debug("Random and repeat: ".$self->{state}{random}."/".$self->{state}{repeat});

  my $id;
  if ($self->{state}{random}) {
    # $self->debug("Taking random ID ".$self->{state}{ranid}." to move back on");
    $id = $self->{state}{ranid};
  } else {
    # $self->debug("Taking straight ID ".$self->{state}{regid}." to move back on");
    $id = $self->{state}{regid};
  }
  $id--;
  if ($id < 0) {
    # $self->debug("beyond beginning of playlist found");
    $id = $#{$self->{playlist}};
  }
  if ($self->{state}{random}) {
    # $self->debug("assigning $id back to random ID");
    $self->{state}{ranid} = $id;
    $self->{state}{regid} = $self->{random}[$id];
  } else {
    # $self->debug("assigning $id back to regular ID");
    $self->{state}{regid} = $id;
    $self->{state}{ranid} = $self->{revrandom}[$id];
  }
  if ($self->{state}{state} != 0) {
    $self->closefile;
    $self->initfile;
  }
}

sub random {
  my $self = shift;
  my $remote = shift;
  my $oldstate = $self->{state}{random};
  # $self->debug("Trying to set ".($remote->{args}[0]));
  if (scalar @{$remote->{args}}) {
    $self->{state}{random} = ($remote->{args}[0]?1:0);
  } else {
    $self->{state}{random} = ! $self->{state}{random};
  }
  if ($oldstate != $self->{state}{random}) {
    if ($self->{state}{random}) {
      $self->info("Turning on Random");
    } else {
      $self->info("Turning off Random");
    }
  }
}

sub repeat {
  my $self = shift;
  my $remote = shift;
  my $oldstate = $self->{state}{repeat};
  if (scalar @{$remote->{args}}) {
    $self->{state}{repeat} = ($remote->{args}[0]?1:0);
  } else {
    $self->{state}{repeat} = ! $self->{state}{repeat};
  }
  if ($oldstate != $self->{state}{repeat}) {
    if ($self->{state}{repeat}) {
      $self->info("Turning on Repeat");
    } else {
      $self->info("Turning off Repeat");
    }
  }
}

sub list {
  my $self = shift;
  my $remote = shift;
  $self->{state}{showlist} = 1;
}

sub jump {
  my $self = shift;
  my $remote = shift;
  my $player = $self->player;
  my $move = $remote->{args}[0];
  push @out, "frame:".(join ',', $self->{state}{curbyte}, $info->{SIZE}, 
                      sprintf("%.2f", $passed), sprintf("%.2f", $ttime));
  (my $dval = $move) =~ s/\D//g;
  my $change;
  if ($move =~/^([\+\-]{1})/) {
    $change = $1;
  }
  if ($move =~/s$/i) {
    $dval = ($dval/$player->tpf);
  }
  $change .= $dval;
  $self->info("Jumping: rcvd \"".$remote->{args}[0]."\", sending jump(".$change.")");
  $player->jump($change);
}
    
sub vol {
  my $self = shift;
  $self->error("Nonsensical. There is no volume in libshout");
}

sub get_info {
  my $self = shift;
  # my $player = $self->player;
  my @out;
  push @out, "state:".$self->{state}{state};
  # 0: stopped   1: Paused  2: Playing
  push @out, "random:".$self->{state}{random};
  push @out, "repeat:".$self->{state}{repeat};
  # push @out, "randomlist:".(join ',', @{$self->{random}});
  # push @out, "revrandomlist:".(join ',', @{$self->{revrandom}});
  # push @out, "randomid:".$self->{state}{ranid};
  push @out, "id:".$self->{state}{regid};
  # push @out, "frame:".(join ',', @{$player->{frame}}) if (ref $player->{frame} && scalar @{$player->{frame}});
  my $file = $self->{playlist}[$self->{state}{regid}];
  my $info = get_mp3info($file);
  my $tag = get_mp3tag($file);
  my $perc = $self->{state}{curbyte}/$info->{SIZE};
  my $ttime = $info->{SECS}.'.'.$info->{MS};
  my $passed = $ttime * $perc;
  push @out, "frame:".(join ',', $self->{state}{curbyte}, $info->{SIZE}, 
                      sprintf("%.2f", $passed), sprintf("%.2f", $ttime));
  
  push @out, 'rateinfo:'.(join ',', $info->{BITRATE}, $info->{FREQUENCY}, ($info->{STEREO}+1));                                   
  if (defined $tag && ref $tag) {
    push @out, "title:".$tag->{TITLE};
    push @out, "artist:".$tag->{ARTIST};
    push @out, "album:".$tag->{ALBIM};
    push @out, "genre:".$tag->{GENRE};
  }
  push @out, "url:".$file;
  push @out, "vol:0 0\n";
  if ($self->{state}{showlist}) {
    push @out, "list:".(join $self->{subsep}, @{$self->{playlist}});
    $self->{state}{showlist} = 0;
  }
  map { $self->debug($_); } @out;
  return \@out;
}

sub mainloop {
  my $self = shift;
  my $socket = $self->socket;
  my $s = IO::Select->new($socket);
  $self->debug("Starting Main Loop, waiting for instructions");
  my $currentstate = $self->{state}{state}; # by default, stopped
  while(1) {
    if ($s->can_read(0)) {
      # $self->debug("-------------------------------------");
      my $remote = eval { $self->read_client; };
      if ($@) {
        $self->crit($@);
        next;
      }
      if (! defined $remote) {
        $self->crit("big issue, reading from client came back null");
        next;
      }
      # $self->debug("Rcvd \"".$remote->{cmd}."\" from ".$remote->{ip}.':'.$remote->{port});
      # nextlist
      # prevlist
      my @cmds = qw/add del play next nextlist prev prevlist pause
                    jump stop info list random repeat vol/;
      if (scalar grep {/^$remote->{cmd}$/} @cmds) {
        my $method = '$self->'.$remote->{cmd}.'($remote)';
        eval "$method";
      }
      $self->send_status;
    }
    if ($currentstate != $self->{state}{state}) {
      if ($self->{state}{state} == 2) {
        $self->initfile;
        if ($currentstate == 1) {
          # $self->jump($self->{state}{curbyte});
        }
      } elsif ($self->{state}{state} == 0) {
        $self->closefile;
      }
    }
    if ($self->{state}{state} == 2) {
      $self->send_chunk;
    }
    $currentstate = $self->{state}{state};
  }
}

sub initfile {
  my $self = shift;
  my $player = $self->player;
  if (defined $self->{_fh}) {
    $self->closefile;
  }
  my $file = $self->{playlist}[$self->{state}{regid}];
  if (! -r $file) {
    $self->crit("unable to find/read $file");
    return;
  }
  if (defined $self->{Pass}{lame}) {
    $self->info("trying to load file: $file and downsample to ".$self->{Pass}{bitrate});
    open( $self->{_fh}, "-|" ) ||
    exec $self->{Pass}{lame}, qw{--mp3input -b}, $self->{Pass}{bitrate}, qw{-m j -h -S}, $file, "-";
    if (! defined $self->{_fh}) {
      $self->crit("Failed to downsample $file: $!");
      return;
    }
  } else {
    $self->info("trying to load straight file: $file");
    if (! open($self->{_fh}, $file)) {
      $self->crit("Failed to open $file: $!");
      return;
    }
  }
  my $tag = get_mp3tag($file);
  my $tagline = "\"".$tag->{TITLE}."\" by ".$tag->{ARTIST};
  $player->updateMetadata($tagline);
  $self->{state}{curbyte} = 0;
  return 1;
}

sub closefile {
  my $self = shift;
  $self->debug("Closing open file");
  $self->{state}{curbyte} = 0;
  close $self->{_fh};
}

sub send_chunk {
  my $self = shift;
  return if (! defined $self->{_fh});
  my $player = $self->player;
  
  $self->{Pass}{chunk} = $self->{Pass}{chunk} || 2048;
  my $buff;
  my $len = sysread($self->{_fh}, $buff, $self->{Pass}{chunk});
  if ($len == 0 || ! defined $len) {
    $self->closefile;
    if ($self->{state}{regid} == $#{$self->{playlist}} && (! $self->{state}{repeat})) {
     $self->{state}{state} = 0;
    } else {
     $self->next;
     $self->initfile;
     $self->send_chunk;
    }
  } else {
    $self->{state}{curbyte} += $len;
    unless ($player->sendData($buff)) {
      $self->crit("send failed: ".$player->error);
    } else {
      $player->sleep;
    }
  }
}

sub send_status {
  my $self = shift;
  my $socket = $self->socket;
  my $out = $self->get_info;
  my $out = join $self->{sep}, @$out;
  $socket->send($out);
}

__END__

=head1 NAME 

Audio::Daemon::Shout - Audio::Daemon backend for libshout (icecast)

=head1 SYNOPSIS

  use Audio::Daemon::Shout;

  # set things up
  my $daemon = new Audio::Daemon::Shout( 
               Port => 9101, Allow => '10.1.1.0/24, 127.0.0.1',
               Pass => { bitrate => 64, ip => '10.10.10.1',
                         name => 'Jay\'s List',
                         port => 18000, mountpoint => 'admin',
                         password => 'secret', chunk => 4096} );

  # this should never return... it is a daemon after all.
  $daemon->mainloop;
  
=head1 DESCRIPTION

This is a Audio::Daemon module for interfacing with libshout and
consequently, icecast servers.  It uses the same client as all
Audio::Daemon modules, except the volume has no effect.

=head1 CONSTRUCTORS

There is but one method to contruct a new C<Audio::Daemon::MPG123::Server> object:

=over 4

=item Audio::Daemon::Shout->new(
      Port => $port, 
      [Log => \&logsub], 
      [Allow => <allowips>], 
      [Deny => <denyips>],
      Pass => { (whole slew of parameters for libshout connection) });

The new method can take the following arguments:

=over 4

=item Port

The local port to start listening and accepting commands on.

=item Log

This takes a reference to a function that's called for logging purposes, the format passed in is:

=over 4

<type>, <msg>, [caller(1)]

where <type> is one of debug, info, error, crit, warn.  
<msg> is the text message, and [caller] is the array 
returned by the second form of the perlfunc caller().
This will give you the method, line number, etc. of 
where the messagee is coming from.  With this logging 
feature, I don't have to worry about syslog, stdout, 
or how to report errors or debug info... you do!

=back 4

=item Allow, Deny

Access Control.  If you specify something for the Allow 
variable, it assumes everything not allowed will be 
denied.  If you specify something to denied it assumes 
everything else is allowed.  Wither neither set, everything 
is allowed.  It accepts multple formats all seperated by 
a comma for multiple entries: 

=over 4

=item <ip>/mask

Either set to full 255.255.255.0 format or bitmask format: /24

=item <ip>

just an IP specified

=item <low ip>-<high ip>

For example: 192.168.10.15-192.168.10.44 so anythine 
between those two addresses would match the rule.

=back 4

=item Pass <hash of parameters>

Pass takes special meaning for whichever module you're working with.
In the case of Audio::Daemon::Shout, there are a whole bunch of
variable that can/should be set:
(These are from and for the libshout module:)
ip, port, mount, password, icy_compat, aim, icq, irc, 
dumpfile, name, url, genre, description, bitrate, ispublic

Custom fields for Audio::Daemon::Shout:
lame, chunk.

lame is the location of the application "lame", used to downsample
the stream as it goes out (usefull for low bandwidth use).  If 
specified it tries to downsample, otherwise it just pipes the 
straight file through.
chunk is the block size to read, in bytes, if you get choppy
sound, you may want to try tweaking this.

=head1 METHODS

=over 4

=item mainloop

Never returns, and in theory, should never exit.

=back

=head1 AUTHOR

Jay Jacobs jayj@cpan.org
First exposure to icecast, still picking things up  if you have any advice or 
experience and you'd like to share, please do so.

=head1 SEE ALSO

Audio::Daemon
Audio::Client
libshout (www.icecast.org)

perl(1).

=cut






