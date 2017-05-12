package Audio::Daemon::MPG123::Client;

use strict;
use IO::Socket;
use IO::Select;
use Audio::Daemon::MPG123;

use vars qw(@ISA $VERSION);
@ISA = qw(Audio::Daemon::MPG123);
my $VERSION='0.9Beta';
 
sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  return $self;
}

sub inline {
  my $self = shift;
  return if (! scalar @_);
  my @args;
  foreach my $arg (@_) {
    if (ref $arg eq 'ARRAY') {
      foreach my $a (@$arg) {
        push @args, $a;
      }
    } else {
      push @args, $arg;
    }
  }
  return @args;
}

sub add {
  my $self = shift;
  my $cmd = join $self->{sep}, 'add', $self->inline(@_);
  $self->sendcmd($cmd);
}
sub del {
  my $self = shift;
  my $cmd = join $self->{sep}, 'del', $self->inline(@_);
  $self->sendcmd($cmd);
}
sub play {
  my $self = shift;
  $self->sendcmd(join $self->{sep}, 'play', $self->inline(@_));
}
sub next {
  # () moves  to next track
  my $self = shift;
  my $cmd = 'next';
  $self->sendcmd($cmd);
}
# I'm taking these out becuase I can't think of how to return the value
# in a very nice way.
# sub nextlist {
#   # () returnes next ID in list
#   my $self = shift;
#   my $cmd = join $self->{sep}, 'nextlist', $self->inline(@_);
#   $self->sendcmd($cmd);
# }
# sub prevlist {
#   my $self = shift;
#   my $cmd = join $self->{sep}, 'prevlist', $self->inline(@_);
#   $self->sendcmd($cmd);
# }
sub prev {
  my $self = shift;
  my $cmd = 'prev';
  $self->sendcmd($cmd);
}
sub pause {
  my $self = shift;
  my $cmd = 'pause';
  $self->sendcmd($cmd);
}
sub jump {
  # () -|+ means relative or absolute, "s" or "f" applies
  my $self = shift;
  my $cmd = join $self->{sep}, 'jump', $self->inline(@_);
  $self->sendcmd($cmd);
}
sub stop {
  my $self = shift;
  my $cmd = 'stop';
  $self->sendcmd($cmd);
}
sub info {
  my $self = shift;
  my $cmd = 'info';
  $self->sendcmd($cmd);
}
sub list {
  my $self = shift;
  my $cmd = 'list';
  $self->sendcmd($cmd);
  if (ref $self->{status}{list}) {
    print "Song List:\n";
    print "  ".(join "\n  ", @{$self->{status}{list}})."\n";
  } else {
    print "Song List:\n  ".$self->{status}{list}."\n";
  }
}
sub random {
  my $self = shift;
  my $cmd;
  if (defined $_[0]) {
    $cmd = join $self->{sep}, 'random', $_[0];
  } else {
    $cmd = 'random';
  }
  $self->sendcmd($cmd);
}
sub repeat {
  my $self = shift;
  my $cmd;
  if (defined $_[0]) {
    $cmd = join $self->{sep}, 'repeat', $_[0];
  } else {
    $cmd = 'repeat';
  }
  $self->sendcmd($cmd);
}
sub vol {
  # (l,r) (sets both equal if only "l" provided
  my $self = shift;
  $cmd = join $self->{sep}, 'vol', $_[0];
  $self->sendcmd($cmd);
}

sub sendcmd {
  my $self = shift;
  my $cmd = shift;
  my $socket = $self->socket;
  my $s = IO::Select->new($socket);
  print "Trying to write: $cmd\n";
  if (scalar $s->can_write(1)) {
    print "Can write, trying to...\n";
    my $bout = $socket->send($cmd);
    $self->debug("Sent out $bout bytes");
    # hey check that it succeeds.
    $self->get_status;
  } else {
    print "Failed to be able to write: $!\n";
  }
}

sub status {
  my $self = shift;
  return $self->{status};
}

sub get_status {
  my $self = shift;
  my $cmd = shift;
  my $socket = $self->socket;
  my $s = IO::Select->new($socket);
  if (scalar $s->can_read(1)) {
    $self->debug("Trying to read from remote");
    my ($newmsg, $remote, $iaddr);
    my $from_addr = $socket->recv($newmsg, 131072, undef);
    $self->debug("Read in ".length $newmsg);
    ($remote->{port}, $iaddr) = sockaddr_in($from_addr);
    $remote->{ip} = inet_ntoa($iaddr);
    $self->debug("Remote :".$remote->{ip}." : ".$remote->{port});
    # return unless ($remote->{ip} eq $self->{Server});
    unless (length $newmsg > 0) {
      $self->warn("Message length was ".(length $newmsg)." returning...");
      return;
    }
    $self->{status} = {};
    foreach my $pair (split $self->{sep}, $newmsg) {
      my ($key, $val) = split(/:\s*/, $pair, 2);
      if ($val=~/$self->{subsep}/) {
        @{$self->{status}{$key}} = split $self->{subsep}, $val;
      } else {
        $self->debug("Setting $key to $val");
        $self->{status}{$key} = $val;
      }
    }
  } else {
    $self->warn("No status returned... can't read");
  }
  return $self->{status};
}

1;
__END__

=head1 NAME

Audio::Daemon::MPG123::Client - The Client portion of Audio::Daemon::MPG123

=head1 SYNOPSIS

  use Audio::Daemon::MPG123::Client;

  my $player = new Audio::Daemon::MPG123::Client(Server => '10.10.10.1', Port => 9101);

  # add in some mp3's 
  $player->add(qw(Goodbye.mp3 Joey.mp3 Clothes_Of_Sand.mp3));
  # set random mode on
  $player->random(1);

  # status returns a hashref full of useful info
  my $status = $player->status;
  print "Random mode is ".($status->{random}?'On':'Off')."\n";
  print "Current track is \"".$status->{title}.'" by '.$status->{artist}."\n";

=head1 DESCRIPTION

This is a frontend to the frontend for mpg123 player.  The client portion communicates
to the Server via UDP message passing and has no dependancies other then IO::Socket and IO::Select.

I feel most of this is best demostrated by examples (set the examples directory).

=head1 CONSTRUCTORS

There is but one method to contruct a new C<Audio::Daemon::MPG123::Client> object:

=over 4

=item Audio::Daemon::MPG123::Client->new(Server => $server, Port => $port, [Log => \&logsub]);

The new method can take the following arguments:

=over 4

=item Server

This specifies the IP address of the C<Audio::Daemon::MPG123::Server> server, it is required.

=item Port

The port the server is listening on (we snag whatever local port IO::Socket chooses).

=item Log

This takes a reference to a function that's called for logging purposes, the format passed in is:

=over 4

<type>, <msg>, [caller(1)]

where <type> is one of debug, info, error, crit, warn.  <msg> is the text message, and [caller] is 
the array returned by the second form of the perlfunc caller().  This will give you the method,
line number, etc. of where the messagee is coming from.  With this logging feature, I don't have to worry
about syslog, stdout, or how to report errors or debug info... you do!

=back 4

=over 4

=over 4

=head1 METHODS

I tried to stay as close the Audio::Play::MPG123 methods as possible with a few exceptions noted below.

=over 4

=item add [list of urls]

Needs to have arguments (array or array ref) of urls to load on the server.  If you're calling an mp3 
file it obviously needs access by the server, not the client.  It can be simple filenames, or urls
including http: urls for streaming to the server.  If there are tracks already in the playlist on the server
these will be tacked on to the end of the list.  If random mode is on, it will re-randomize the entire list
when it is finished adding (see the random feature).

=item del [list of index numbers]

Takes either the index number of tracks to remove or the keyword "all" to clear out the tracks.  If the
player is currently playing a track you removed it will internally call "next" to move the next track.  If 
you remove all tracks, it will cease to play until you add tracks back in.

=item stop

Stops the player if it's playing, otherwise it won't stop a non-playing player.

=item play

Starts the player if it's not playing, otherwise it lets a playing player play.

=item pause

Pauses the player if it's not paused, unpauses if it is paused.

=item next

Moves to the next track, this should not cause it to start playing if it is isn't currently.

=item prev

Goes in the opposite direction of next, but again, won't start it playing if it's not.

=item list

This causes the current playlist to be sent back with the next status update that normally 
occurs after each instruction (including the list command).  The Play List is then accessed
via the B<status> method.

=item jump ([+-]#[s])

Jump is very similiar to the Audio::Play::MPG123 command.  It accepts one argument that can get
a wee bit complicated but follow me on this, it has three parts, only one part is required:

<plus or minus><a digit><seconds>

This is best described with examples:

10s   (moves 10 seconds from the beginning of the track)
165s  (moves to 2:35 in the current track)
+10s  (moves forward 10 seconds from current track position)
-10s  (moves back 10 seconds from current track position)
10    (moves to the tenth frame -- see the "frame" status)

Most people would avoid the last example, but it's there for compatability issues.

=item vol ([vol|left], [right)

If you have the Audio::Mixer volume on the server, it will set the volume.  If one argument is passed in
it will equally set the right and left channels, if two arguments are passed in it will set left and right 
volumes respectively.

=item random (1|0)

Turns on or off the random mode.  The random playlist is really created when tracks are added or removed
from the current playlist.  This way each track is played in a "random" order before repeating any single
track.  If the playlist is modified in any way, the random playlist will be recreated opening the probability
that a track will be repeated before all tracks are played.

=item repeat (1|0)

Turns on or off the repeat function.  This doesn't mean it will repeat a track it means that it will wrap
around to the beginning of a playlist when the end is reached.  With repeat off, it will stop playing once
all tracks have been played.

=item info

This is basically a null command, tell the server to send the current status information which it will
do after any command.

=item status

This is the meat and potatoes of the app.  

After every command sent to the server, the server responds with all sorts of information processed
behind the scene.  Calling this method returns a hash reference to all the information last retrieved
from the server.  Currently the values in the status are:

=over 4

=item state

0 is stopped, 1 is paused, 2 is playing

=item random

1 or 0 (meaning true of false, yes or no)

=item repeat

1 or 0

=item id

Current index (starting at 0) of the track being playing in the playlist.

=item frame

This is taken directly from c<Audio::Play::MPG123>, so I'd suggest looking
there for more detail, but the basic format is 
<current frame>,<frames remeaining>,<seconds passed>,<seconds remaining>.
the frames are determined by the mp3 file (as far as I get it).  In order to
get the total seconds in the track you'd add up the <seconds passed> and the
<seconds remaining>.  Again, see c<Audio::Play::MPG123> for details on this.

=item title, artist, album, genre

The respective value from the MP3 ID3 tag of the current track.

=item url

The current url (file position, or other) of current track.

=item vol

"l,r" value (left comma right), if Audio::Mixer is loaded on the server, otherwise it's undef.

=item list

Only set after specifically calling "list" and is a reference to an array of urls in the (non-random) order
being used by the player.

=back 4

It might be benificial to double check the keys returned by b<status> as there may be some things added
that *gasp* the documentation wasn't updated for.

=back

=head1 AUTHOR

Jay Jacobs jayj@cpan.org

=head1 SEE ALSO

Audio::Daemon::MPG123

Audio::Play::MPG123

perl(1).

=cut





