package Audio::Daemon::Xmms;

use strict;
use Audio::Daemon;
use IO::Socket;
use IO::Select;
use Xmms ();
use Xmms::Remote ();
use Xmms::Config ();
use MP3::Info;

use vars qw(@ISA $VERSION);
@ISA = qw(Audio::Daemon);
$VERSION='0.99Beta';

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  $self->remote(Xmms::Remote->new);
  $self->config(Xmms::Config->new(Xmms::Config->file));
  my $remote = $self->remote;

  unless ($remote->is_running) {
    exec "xmms" unless (fork());
    sleep 1;
  }
  $self->{state} = {random => $remote->is_shuffle, repeat => $remote->is_repeat};
  return $self;
}

sub remote {
  my $self = shift;
  $self->{_remote} = shift if (scalar @_);
  return $self->{_remote};
}

sub config {
  my $self = shift;
  $self->{_config} = shift if (scalar @_);
  return $self->{_config};
}

sub stop {
  my $self = shift;
  $self->remote->stop;
}
  
sub play {
  my $self = shift;
  my $remote = shift;
  if (defined $remote->{args}[0]) {
    $self->info("trying to play index: ".$remote->{args}[0]);
    $self->remote->set_playlist_pos($remote->{args}[0]);
  }
  $self->remote->play;
}

sub pause {
  my $self = shift;
  $self->remote->pause;
}

sub add {
  my $self = shift;
  my $remote = shift;
  $self->remote->playlist($remote->{args});
}

sub del {
  my $self = shift;
  my $remote = shift;
  if ($remote->{args}[0] eq 'all') {
    $self->remote->stop;
    $self->remote->playlist_clear;
  } else {
    foreach (sort { $b <=> $a } @{$remote->{args}}) {
      $self->debug("Trying to remove index: $_");
      $self->remote->playlist_delete($_);
    }
  }
}

sub next {
  my $self = shift;
  $self->remote->playlist_next;
}

sub prev {
  my $self = shift;
  $self->remote->playlist_prev;
}

sub random {
  my $self = shift;
  my $remote = shift;
  $self->debug("Trying to set ".($remote->{args}[0]));
  if (defined $remote->{args}[0] && $self->remote->is_shuffle != $remote->{args}[0]) {
    $self->remote->toggle_shuffle;
    $self->info("Toggled shuffle");
  }
}

sub repeat {
  my $self = shift;
  my $remote = shift;
  $self->debug("Trying to set ".($remote->{args}[0]));
  if (defined $remote->{args}[0] && $self->remote->is_repeat != $remote->{args}[0]) {
    $self->remote->toggle_repeat;
    $self->info("Toggled repeat");
  }
}

sub list {
  my $self = shift;
  my $remote = shift;
  # $self->debug(join "\n", @{$self->{playlist}});
  $self->{state}{showlist} = 1;
}

sub jump {
  my $self = shift;
  my $remote = shift;
  my $move = $remote->{args}[0];
  (my $dval = $move) =~ s/\D//g;
  my $change = $dval;
  if ($move =~/s$/i) {
    $dval *= 1000;
  }
  if ($move =~/^([\+\-]{1})/) {
    $change = $1;
    my $elapse = $self->remote->get_output_time;
    my $ttime = $self->remote->get_playlist_time($self->remote->get_playlist_pos);
    if ($change eq '+') {
      $dval += $elapse;
      $dval = $ttime if ($dval > $ttime);
    } else {
      $dval = $elapse - $dval;
      $dval = 0 if ($dval < 0);
    }
  }
  $self->info("Jumping: rcvd \"".$remote->{args}[0]."\", sending jump(".$change.")");
  $remote->jump_to_time($dval);
  # $player->jump($change);
}
    
sub vol {
  my $self = shift;
  my $remote = shift;
  # set vol
}

sub get_info {
  my $self = shift;
  my @out;
  if ($self->remote->is_paused) {
    push @out, "state:1";
  } elsif ($self->remote->is_playing) {
    push @out, "state:2";
  } else {
    push @out, "state:0";
  }
  # 0: stopped   1: Paused  2: Playing
  push @out, "random:".$self->remote->is_shuffle;
  push @out, "repeat:".$self->remote->is_repeat;
  # push @out, "revrandomlist:".(join ',', @{$self->{revrandom}});
  # push @out, "randomid:".$self->{state}{ranid};
  push @out, "id:".$self->remote->get_playlist_pos;
  push @out, 'rateinfo:'.(join ',', $self->remote->get_info);
  my $elapse = $self->remote->get_output_time;
  my $ttime = $self->remote->get_playlist_time($self->remote->get_playlist_pos);
  my $tdiff = $ttime - $elapse;
  push @out, 'frame:'.$elapse.','.$ttime.','.sprintf('%.2f', $elapse/1000).','.sprintf('%.2f', ($tdiff/1000));

  my $tag = get_mp3tag($self->remote->get_playlist_file($self->remote->get_playlist_pos));
  if (defined $tag && ref $tag) {
    push @out, "title:".$tag->{TITLE};
    push @out, "artist:".$tag->{ARTIST};
    push @out, "album:".$tag->{ALBIM};
    push @out, "genre:".$tag->{GENRE};
  }
  push @out, "url:".$self->remote->get_playlist_file($self->remote->get_playlist_pos);
  my($lvol, $rvol) = $self->remote->get_volume;
  push @out, "vol:$lvol $rvol\n";
  if ($self->{state}{showlist}) {
    push @out, "list:".(join $self->{subsep}, @{$self->remote->get_playlist_files});
    $self->{state}{showlist} = 0;
  }
  map { $self->debug($_) } @out;
  return \@out;
}

sub mainloop {
  my $self = shift;
  my $socket = $self->socket;
  my $s = IO::Select->new($socket);
  # $self->debug("Starting Main Loop, waiting for instructions");
  while(1) {
    if ($s->can_read(0)) {
      $self->debug("-------------------------------------");
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
  }
}

sub send_status {
  my $self = shift;
  my $socket = $self->socket;
  my $out = $self->get_info;
  my $out = join $self->{sep}, @$out;
  $socket->send($out);
}

1;

__END__

=head1 NAME 

Audio::Daemon::Xmms - The Xmms Server portion of Audio::Daemon

=head1 SYNOPSIS

  use Audio::Daemon::Xmms;

  # set things up
  my $daemon = new Audio::Daemon::Xmms(Port => 9101);

  # this should never return... it is a daemon after all.
  $daemon->mainloop;
  
=head1 DESCRIPTION

The Server portion of Audio::Daemon::Xmms, putting a UDP interface to Xmms, and a single
client library.  Gives the user full control over how to daemonize, keep running, 
monitor it, log messages, maintain access control, etc.

=head1 CONSTRUCTORS

There is but one method to contruct a new C<Audio::Daemon::Xmms> object:

=over 4

=item Audio::Daemon::Xmms->new(Port => $port, [Log => \&logsub], [Allow => <allowips>], [Deny => <denyips>]);

The new method can take the following arguments:

=over 4

=item Port

The local port to start listening and accepting commands on.

=item Log

This takes a reference to a function that's called for logging purposes, the format passed in is:

=over 4

<type>, <msg>, [caller(1)]

where <type> is one of debug, info, error, crit, warn.  <msg> is the text message, and [caller] is
the array returned by the second form of the perlfunc caller().  This will give you the method,
line number, etc. of where the messagee is coming from.  With this logging feature, I don't have to worry
about syslog, stdout, or how to report errors or debug info... you do!

=back 4

=item Allow, Deny

Access Control.  If you specify something for the Allow variable, it assumes everything not allowed will
be denied.  If you specify something to denied it assumes everything else is allowed.  Wither neither
set, everything is allowed.  It accepts multple formats all seperated by a comma for multiple entries:

=over 4

=item <ip>/mask

Either set to full 255.255.255.0 format or bitmask format: /24

=item <ip>

just an IP specified

=item <low ip>-<high ip>

For example: 192.168.10.15-192.168.10.44 so anythine between those two addresses would match the rule.

=back 4

=head1 METHODS

=over 4

=item mainloop

Never returns, and in theory, should never exit.

=back

=head1 INFO

The info routine from the client will return the following fields:
state, random, repeat, id, rateinfo, frame, title, artist, album, genre, vol and optionally list.

=over 4

=item state

0 is stopped, 1 is paused, 2 is playing

=item random

1 means random is on, 0 means random is off.  And this random uses 
the xmms random feature, not my internal random feature.

=item repeat

1 means repeat is on, 0 means repeat is off.

=item id

current track ID (starting at track 0) from the list of current tracks
in the playlist.

=item rateinfo

Directly from xmms, I think it's kbps, something else, and stereo seperated by commas.

=item frame

I tried to mimick the mpg123 fields for frame so four fields are delivered.  The first
field is the time passed in milliseconds on the current track.  The second is the total
number of milliseconds in the current track.  The third is a float (%.1f I think) of 
time passed in current track, and the fourth (pay attention now), is the remaining 
seconds (%.1f again) of the current track.

=item title, artist, album, genre

All of these are from the ID3 track

=item vol

left and right volume from Xmms

=item list

see Audio::Daemon::Client on this format, it's the same across the board.

=back 4

=head1 AUTHOR

Jay Jacobs jayj@cpan.org

=head1 SEE ALSO

Audio::Daemon

Xmms

perl(1).

=cut
