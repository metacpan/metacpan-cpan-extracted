package App::Procapult;

use strictures 2;
use IO::Socket::UNIX;
use IO::Handle;
use String::ShellQuote qw(shell_quote);
use Moo;
use MooX::Options protect_argv => 0, flavour => [ qw(require_order) ];

our $VERSION = '0.009001'; # 0.9.1

$VERSION = eval $VERSION;

option socket => (
  is => 'ro',
  format => 's',
  required => 1,
  short => 's',
  doc => 'unix socket path'
);

sub run {
  my ($self) = @_;
  if (my $cmd = shift @ARGV) {
    return $self->${\(
      $self->can("run_${cmd}")
      ||die "Invalid command ${cmd}: must be (start|stop|run|die|status|watch)\n"
    )}(@ARGV);
  }
  require Proc::Apult;
  return Proc::Apult->new(socket_path => $self->socket)->run;
}

sub run_start {
  my ($self, @args) = @_;
  my $sock = $self->_connect_discard;
  print $sock join(' ', start => shell_quote @args)."\n";
  my $line = <$sock>;
  print $line;
}

sub run_stop {
  my ($self) = @_;
  my $sock = $self->_connect_discard;
  print $sock "stop\n";
  my $line = <$sock>;
  print $line;
}

sub run_die {
  print { $_[0]->_connect_discard } "die\n";
}

sub run_status {
  my ($self) = @_;
  my $sock = $self->_connect;
  my $line = <$sock>;
  print $line;
}

sub run_watch {
  my ($self) = @_;
  my $sock = $self->_connect;
  STDOUT->autoflush(1);
  while (my $line = <$sock>) {
    print $line;
  }
}

sub run_run {
  my ($self, @args) = @_;
  my $sock = $self->_connect_discard;
  print $sock join(' ', start => shell_quote @args)."\n";
  STDOUT->autoflush(1);
  my $first = <$sock>;
  print $first;
  return unless $first =~ /^STATUS: started/;
  while (my $line = <$sock>) {
    print $line;
    return if $line =~ /^STATUS: stopped/;
  }
}

sub _connect {
  my ($self) = @_;
  my $socket = IO::Socket::UNIX->new(
    Peer => $self->socket,
  ) or die "Couldn't create ${\$self->socket} - $!\n";
  return $socket;
}

sub _connect_discard {
  my ($self) = @_;
  my $socket = $self->_connect;
  my $discard = <$socket>;
  return $socket;
}

1;

=head1 NAME

App::Procapult - Hand cranked process launcher

=head1 SYNOPSIS

  $ procapult -s ./ctrl

Then in another shell ...

  $ socat - ./ctrl
  STATUS: stopped
  start sleep 3
  STATUS: started 31563 sleep 3
  STATUS: stopped
  start bash
  STATUS: started 31585 bash

And play with the bash in the first shell until you're bored then

  stop
  STATUS: stopped
  die
  $

and with that, your procapult will expire in a puff of logic.

=head1 DESCRIPTION

The idea for procapult is to have a process launcher that sits around
doing nothing, until you tell it to start something, at which point it
runs that until it exits or you tell it to stop it.

A procapult can, by design, only run one process at once - it's expected
to be started in a screen/tmux/dtach window or an xterm, so the behaviour
is as simple as possible.

To control your procapult, you make a unix socket connection to the
control socket passed when you started it. Multiple clients are permitted
at the same time, and if they step on each others' toes that's considered
operator error on your part.

The protocol for the socket is so simple even I can understand it:

=over 4

=item * On connect, procapult sends its current status

=item * When the status changes, procapult sends the new status

=item * Status lines look like one of

  STATUS: started 12345 some shell process
  STATUS: stopped

where 12345 is the pid of the process procapult is currently running

=item * Valid commands are 'start', 'stop' and 'die'

=item * 'start some shell process' passes the string 'some shell process'
to perl's exec()

=item * 'stop' causes procapult to send its process a SIGHUP

=item * 'die' causes procapult itself to commit harakiri

=item * If your command is malformed or makes no sense, procapult sends
an error line

=item * Error lines look like

  ERROR: some description of what went wrong

=item * A successful command returns nothing, on the assumption that a status
line will be along shortly to tell you what happened

=item * That's all, folks.

=back

=head1 SIGNAL HANDLING

procapult traps both INT and QUIT, because it's likely sat at the root of
a terminal. So Ctrl-C and Ctrl-\ won't blow it up. If you actually want your
procapult to fall down and go boom, you can either send it a SIGTERM, which
incidentally is what 'kill 12345' will do anyway, or send it a die  -

  $ echo die | socat - /path/to/procapult/socket

=head1 SCRIPTING CLIENT

You can also avoid needing to use socat (or your own unix socket logic) by
using the built-in client:

  # sends start, reads one line, prints, exits
  #
  $ procapult -s foo start some process name
  STATUS: started 12345 some process name
  $

  # sends stop, reads one line, prints, exits
  #
  $ procapult -s foo stop
  STATUS: stopped
  $

  # sends start, reads one line, exits if not started, reads until stop, exits
  #
  $ procapult -s foo run sleep 3
  STATUS: started 12345 sleep 3
  STATUS: stopped
  $

  # sends die to kill the procapult, exits
  #
  $ procapult -s foo die
  $

  # reads status, prints, exits
  #
  $ procapult -s foo status
  STATUS: stopped
  $

  # reads status, prints, repeats until killed
  #
  $ procapult -s foo watch
  STATUS: stopped
  STATUS: started 12345 sleep 3
  STATUS: stopped
  ...

=head1 USAGE EXAMPLE

The purpose for which this code was originally written was that I tend to
run clusters of four xterms locally and connect them to matching server
sessions. Which gets boring when my connection's a bit patchy. So what I
can now do is -

  # on the server
  #
  $ for i in tl tr bl br; do dtach -c ~/dtach/0$i -z bash; done

which starts four dtach sessions running bash (if you don't know dtach,
think "screen for grumpy minimalists" and you won't be far wrong). Then on
my machine I start my four xterms, and in each one start a procapult -

  # in different terminals -
  #
  $ procapult -s ~/clus0/tl
  $ procapult -s ~/clus0/tr
  $ procapult -s ~/clus0/bl
  $ procapult -s ~/clus0/br

and then with that done, I can cause a full (re)connect simply with -

  $ for i in tl tr bl br; do
      procapult -s ~/clus0/$i start ssh -t servername dtach -a dtach/0$i;
    done

noting that the -t is required to get a tty allocated even though we're not
just letting ssh start a shell, and if any of the four haven't died then
you'll just get an error from those, which procapult will duly print out
and assume is now your problem. Obviously, if you care about noticing when
something falls over, you wanted either 'run' instead of 'start' or to
run 'status' or 'watch' as preferred.

=head1 SUPPORT

While you can, in theory, email me, and I will, in theory, reply at some
point, you're far better bugging me on #web-simple on irc.perl.org. I'm
'mst' on there, and my client is permanently connected, so while I might
not reply until tomorrow if I've already called pubtime I should reply
eventually.

=head1 AUTHOR

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2015 the App::Procapult L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
