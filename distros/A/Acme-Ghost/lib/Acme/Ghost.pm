package Acme::Ghost;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acme::Ghost - An yet another view to daemon processes

=head1 SYNOPSIS

    use Acme::Ghost

    my $g = Acme::Ghost->new(
        logfile     => '/tmp/daemon.log',
        pidfile     => '/tmp/daemon.pid',
        user        => 'nobody',
        group       => 'nogroup',
    );

    $g->daemonize;

    $g->log->info('Oops! I am Your Ghost');

=head1 DESCRIPTION

An yet another view to daemon processes

=head2 new

    my $g = Acme::Ghost->new(
        name        => 'myDaemon',
        user        => 'nobody',
        group       => 'nogroup',
        pidfile     => '/var/run/myDaemon.pid',
        logfile     => '/var/log/myDaemon.log',
        ident       => 'myDaemon',
        logopt      => 'ndelay,pid',
        facility    => 'user',
        logger      => Mojo::Log->new,
        loglevel    => 'debug',
        loghandle   => IO::Handler->new,
    );

=head1 ATTRIBUTES

This class implements the following attributes

=head2 facility

    facility    => 'user',

This attribute sets facility for logging

See L<Acme::Ghost::Log/facility>

=head2 group

    group       => 'nogroup',
    group       => 65534,

This attribute sets group/gid for spawned process

=head2 ident

    ident       => 'myDaemon',

This attribute sets ident string for system log (syslog)

=head2 logfile

    logfile     => '/var/log/myDaemon.log',

This attribute sets log file path. By default all log entries will be printed to syslog

See L<Acme::Ghost::Log/file>

=head2 logger

    logger      => Mojo::Log->new,

This attribute perfoms to set predefined logger, eg. Mojo::Log.
If you set this attribute, the specified logger will be used as the preferred logger

=head2 loghandle

Log filehandle, defaults to opening "file" or uses syslog if file not specified

See L<Acme::Ghost::Log/handle>

=head2 loglevel

    loglevel    => 'debug',

This attribute sets the log level

See L<Acme::Ghost::Log/level>

=head2 logopt

    logopt      => 'ndelay,pid',

This attribute contains zero or more of the options

See L<Acme::Ghost::Log/logopt>

=head2 name

    name        => 'myDaemon',

This attribute sets name of daemon. Default: script name C<basename($0)>

=head2 pidfile

    pidfile     => '/var/run/myDaemon.pid',

This attribute sets PID file path. Default: ./<NAME>.pid

=head2 user

    user        => 'nobody',
    user        => 65534,

This attribute sets user/uid for spawned process

=head1 METHODS

This class implements the following methods

=head2 again

This method is called immediately after creating the instance and returns it

B<NOTE:> Internal use only for subclasses!

=head2 daemonize

    $g = $g->daemonize;

Main routine for just daemonize.
This routine will check on the pid file, safely fork, create the pid file (storing the pid in the file),
become another user and group, close STDIN, STDOUT and STDERR, separate from the process group (become session leader),
and install $SIG{INT} to remove the pid file. In otherwords - daemonize.
All errors result in a die

=head2 filepid

    my $filepid = $g->filepid;

This method returns L<Acme::Ghost::FilePid> object

=head2 flush

    $self = $self->flush;

This internal method flush (resets) process counters to defaults. Please do not use this method in your inherits

=head2 is_daemonized

    $g->is_daemonized or die "Your ghost process really is not a daemon"

This method returns status of daemon:

    True - the process is an daemon;
    False - the process is not daemon;

=head2 is_spirited

    my $is_spirited = $g->is_spirited;

This method returns status of spirit:

    True - the process is an spirit;
    False - the process is not spirit;

=head2 log

    my $log = $g->log;

This method returns L<Acme::Ghost::Log> object

=head2 ok

    $g->ok or die "Interrupted!";

This method checks process state and returns boolean status of healthy.
If this status is false, then it is immediately to shut down Your process
as soon as possible, otherwise your process will be forcibly destroyed
within 7 seconds from the moment your process receives the corresponding signal

=head2 pid

    print $g->pid;

This method returns PID of the daemon

=head2 set_gid

    $g = $g->set_gid('1000 10001 10002');
    $g = $g->set_gid(1000);
    $g = $g->set_gid('nogroup');
    $g = $g->set_gid;

Become another group. Arguments are groups (or group ids or space delimited list of group ids). All errors die

=head2 set_uid

    $g = $g->set_uid(1000);
    $g = $g->set_uid('nobody');
    $g = $g->set_uid;

Become another user. Argument is user (or userid). All errors die

=head1 CONTROL METHODS

List of LSB Daemon Control Methods

These methods can be used to control the daemon behavior.
Every effort has been made to have these methods DWIM (Do What I Mean),
so that you can focus on just writing the code for your daemon.

=head2 ctrl

    exit $g->ctrl( shift @ARGV, 'USR2' );
      # start, stop, restart, reload, status

Daemon Control Dispatcher with using USR2 to reloading

    exit $g->ctrl( shift @ARGV, 0 );

This example shows how to forced suppress reloading (disable send users signals to daemon)

=head2 reload

    $exit_code = $g->reload; # SIGHUP (by default)
    $exit_code = $g->reload('USR2'); # SIGUSR2
    $exit_code = $g->reload(12); # SIGUSR2 too
    say "Reloading ". $g->pid;

This method performs sending signal to Your daemon and return C<0> as exit code.
This method is primarily intended to perform a daemon reload

=head2 restart

    $exit_code = $g->restart;
    if ($exit_code) {
        say STDERR "Restart failed " . $g->pid;
    } else {
        say "Restart successful";
    }

This method performs restarting the daemon and returns C<0> as successfully
exit code or C<1> in otherwise

=head2 start

    my $exit_code = $g->start;
    say "Running ". $g->pid;
    exit $exit_code;

This method performs starting the daemon and returns C<0> as exit code.
The spawned process calls the startup handler and exits with status C<0>
as exit code without anything return

=head2 status

    if (my $runned = $g->status) {
        say "Running $runned";
    } else {
        say "Not running";
    }

This method checks the status of running daemon and returns its PID (alive).
The method returns 0 if it is not running (dead).

=head2 stop

    if (my $runned = $g->stop) {
        if ($runned < 0) {
            die "Daemon " . $g->pid ." is still running";
        } else {
            say "Stopped $runned";
        }
    } else {
        say "Not running";
    }

This method performs stopping the daemon and returns:

    +PID -- daemon stopped successfully
    0    -- daemon is not running
    -PID -- daemon is still running, stop failed

=head1 HOOKS

This class implements the following user-methods (hooks).
Each of the following methods may be implemented (overwriting) in a your class

=head2 preinit

    sub preinit {
        my $self = shift;
        # . . .
    }

The preinit() method is called before spawning (forking)

=head2 init

    sub init {
        my $self = shift;
        # . . .
    }

The init() method is called after spawning (forking) and after daemonizing

=head2 startup

    sub startup {
        my $self = shift;
        # . . .
    }

The startup() method is called after daemonizing in service mode

This is your main hook into the service, it will be called at service startup.
Meant to be overloaded in a subclass.

=head2 cleanup

    sub cleanup {
        my $self = shift;
        my $scope = shift; # 0 or 1
        # . . .
    }

The cleanup() method is called at before exit
This method passes one argument:

    0 -- called at normal DESTROY;
    1 -- called at interrupt

B<NOTE!> On DESTROY phase logging is unpossible.
We not recommended to use logging in this method

=head2 hangup

    sub hangup {
        my $self = shift;
        # . . .
    }

The hangup() method is called on HUP or USR2 signals

For example (on Your inherit subclass):

    sub init {
        my $self = shift;

        # Listen USR2 (reload)
        $SIG{HUP} = sub { $self->hangup };
    }
    sub hangup {
        my $self = shift;
        $self->log->debug(">> Hang up!");
    }

=head1 EXAMPLES

=over 4

=item ghost_simple.pl

This is traditional way to start daemons

    use Acme::Ghost;

    my $g = Acme::Ghost->new(
        logfile => 'daemon.log',
        pidfile => 'daemon.pid',
    );

    my $cmd = shift(@ARGV) // 'start';
    if ($cmd eq 'status') {
        if (my $runned = $g->status) {
            print "Running $runned\n";
        } else {
            print "Not running\n";
        }
        exit 0; # Ok
    } elsif ($cmd eq 'stop') {
        if (my $runned = $g->stop) {
            if ($runned < 0) {
                print STDERR "Failed to stop " . $g->pid . "\n";
                exit 1; # Error
            }
            print "Stopped $runned\n";
        } else {
            print "Not running\n";
        }
        exit 0; # Ok
    } elsif ($cmd ne 'start') {
        print STDERR "Command incorrect\n";
        exit 1; # Error
    }

    # Daemonize
    $g->daemonize;

    my $max = 10;
    my $i = 0;
    while (1) {
        $i++;
        sleep 3;
        $g->log->debug(sprintf("> %d/%d", $i, $max));
        last if $i >= $max;
    }

=item ghost_acme.pl

Simple acme example of daemon with reloading demonstration

    my $g = MyGhost->new(
        logfile => 'daemon.log',
        pidfile => 'daemon.pid',
    );

    exit $g->ctrl(shift(@ARGV) // 'start'); # start, stop, restart, reload, status

    1;

    package MyGhost;

    use parent 'Acme::Ghost';

    sub init {
        my $self = shift;
        $SIG{HUP} = sub { $self->hangup }; # Listen USR2 (reload)
    }
    sub hangup {
        my $self = shift;
        $self->log->debug("Hang up!");
    }
    sub startup {
        my $self = shift;
        my $max = 100;
        my $i = 0;
        while ($self->ok) {
            $i++;
            sleep 3;
            $self->log->debug(sprintf("> %d/%d", $i, $max));
            last if $i >= $max;
        }
    }

    1;

=item ghost_ioloop.pl

L<Mojo::IOLoop> example

    my $g = MyGhost->new(
        logfile => 'daemon.log',
        pidfile => 'daemon.pid',
    );

    exit $g->ctrl(shift(@ARGV) // 'start', 0); # start, stop, restart, reload, status

    1;

    package MyGhost;

    use parent 'Acme::Ghost';
    use Mojo::IOLoop;

    sub init {
        my $self = shift;
        $self->{loop} = Mojo::IOLoop->new;
    }
    sub startup {
        my $self = shift;
        my $loop = $self->{loop};
        my $i = 0;

        # Add a timers
        my $timer = $loop->timer(5 => sub {
            my $l = shift; # loop
            $self->log->info("Timer!");
        });
        my $recur = $loop->recurring(1 => sub {
            my $l = shift; # loop
            $l->stop unless $self->ok;
            $self->log->info("Tick! " . ++$i);
            $l->stop if $i >= 10;
        });

        $self->log->debug("Start IOLoop");

        # Start event loop if necessary
        $loop->start unless $loop->is_running;

        $self->log->debug("Finish IOLoop");
    }

    1;

=item ghost_ae.pl

AnyEvent example

    my $g = MyGhost->new(
        logfile => 'daemon.log',
        pidfile => 'daemon.pid',
    );

    exit $g->ctrl(shift(@ARGV) // 'start', 0); # start, stop, restart, reload, status

    1;

    package MyGhost;

    use parent 'Acme::Ghost';
    use AnyEvent;

    sub startup {
        my $self = shift;
        my $quit = AnyEvent->condvar;
        my $i = 0;

        # Create watcher timer
        my $watcher = AnyEvent->timer (after => 1, interval => 1, cb => sub {
            $quit->send unless $self->ok;
        });

        # Create process timer
        my $timer = AnyEvent->timer(after => 3, interval => 3, cb => sub {
            $self->log->info("Tick! " . ++$i);
            $quit->send if $i >= 10;
        });

        $self->log->debug("Start AnyEvent");
        $quit->recv; # Run!
        $self->log->debug("Finish AnyEvent");
    }

    1;

=item ghost_nobody.pl

This example shows how to start daemons over nobody user and logging to syslog (default)

    my $g = MyGhost->new(
        pidfile => '/tmp/daemon.pid',
        user    => 'nobody',
        group   => 'nogroup',
    );

    exit $g->ctrl(shift(@ARGV) // 'start', 0); # start, stop, restart, status

    1;

    package MyGhost;

    use parent 'Acme::Ghost';

    sub startup {
        my $self = shift;
        my $max = 100;
        my $i = 0;
        while ($self->ok) {
            $i++;
            sleep 3;
            $self->log->debug(sprintf("> %d/%d", $i, $max));
            last if $i >= $max;
        }
    }

    1;

=back

=head1 DEBUGGING

You can set the C<ACME_GHOST_DEBUG> environment variable to get some advanced diagnostics information printed to
C<STDERR>.

    ACME_GHOST_DEBUG=1

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<CTK::Daemon>, L<Net::Server::Daemonize>, L<Mojo::Server>,
L<Mojo::Server::Prefork>, L<Daemon::Daemonize>, L<MooseX::Daemonize>,
L<Proc::Daemon>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

our $VERSION = '1.03';

use Carp qw/carp croak/;
use Cwd qw/getcwd/;
use File::Basename qw//;
use File::Spec qw//;
use POSIX qw/ :sys_wait_h SIGINT SIGTERM SIGQUIT SIGKILL SIGHUP SIG_BLOCK SIG_UNBLOCK /;

use Acme::Ghost::FilePid;
use Acme::Ghost::Log;

use constant {
    DEBUG       => $ENV{ACME_GHOST_DEBUG} || 0,
    IS_ROOT     => (($> == 0) || ($< == 0)) ? 1 : 0,
    SLEEP       => 60,
    INT_TRIES   => 3,
    LSB_COMMANDS=> [qw/start stop reload restart status/],
};

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $name = $args->{name} || File::Basename::basename($0);
    my $user = $args->{user} // '';
    my $group = $args->{group} // '';

    # Get UID by User
    my $uid = $>; # Effect. UID
    if (IS_ROOT) {
        if ($user =~ /^(\d+)$/) {
            $uid = $user;
        } elsif (length($user)) {
            $uid = getpwnam($user) || croak "getpwnam failed - $!\n";
        }
    }
    $user = getpwuid($uid || 0) unless length $user;

    # Get GID by Group
    my $gids = $); # Effect. GIDs
    if (IS_ROOT) {
        if ($group =~ /^(\d+)$/) {
            $gids = $group;
        } elsif (length($group)) {
            $gids = getgrnam($group) || croak "getgrnam failed - $!\n";
        }
    }
    my $gid  = (split /\s+/, $gids)[0]; # Get first GID
    $group = getpwuid($gid || 0) unless length $group;

    # Check name
    croak "Can't create unnamed daemon\n" unless $name;

    my $self = bless {
        name        => $name,
        user        => $user,
        group       => $group,
        uid         => $uid,
        gid         => $gid,
        gids        => $gids,

        # PID
        pidfile     => $args->{pidfile} || File::Spec->catfile(getcwd(), sprintf("%s.pid", $name)),
        _filepid    => undef,

        # Log
        facility    => $args->{facility},
        logfile     => $args->{logfile},
        ident       => $args->{ident} || $name,
        logopt      => $args->{logopt},
        logger      => $args->{logger},
        loglevel    => $args->{loglevel},
        loghandle   => $args->{loghandle},
        _log        => undef,

        # Runtime
        initpid     => $$,  # PID of root process
        ppid        => 0,   # PID before daemonize
        pid         => 0,   # PID daemonized process
        daemonized  => 0,   # 0 - no daemonized; 1 - daemonized
        spirited    => 0,   # 0 - is not spirit; 1 - is spirit (See ::Prefork)

        # Manage
        ok          => 0,   # 1 - Ok. Process is healthy (ok)
        signo       => 0,   # The caught signal number
        interrupt   => 0,   # The interrupt counter

    }, $class;
    return $self->again(%$args);
}
sub again { shift }
sub log {
    my $self = shift;
    return $self->{_log} //= Acme::Ghost::Log->new(
        facility    => $self->{facility},
        ident       => $self->{ident},
        logopt      => $self->{logopt},
        logger      => $self->{logger},
        level       => $self->{loglevel},
        file        => $self->{logfile},
        handle      => $self->{loghandle},
    );
}
sub filepid {
    my $self = shift;
    return $self->{_filepid} //= Acme::Ghost::FilePid->new(
        file => $self->{pidfile}
    );
}
sub set_uid {
    my $self = shift;
    my $uid = shift // $self->{uid};
    return $self unless IS_ROOT; # Skip if no ROOT
    return $self unless defined $uid; # Skip if no UID

    # Set UID
    POSIX::setuid($uid) || die "Setuid $uid failed - $!\n";
    if ($< != $uid || $> != $uid) { # check $> also (rt #21262)
        $< = $> = $uid; # try again - needed by some 5.8.0 linux systems (rt #13450)
        if ($< != $uid) {
            die "Detected strange UID. Couldn't become UID \"$uid\": $!\n";
        }
    }

    return $self;
}
sub set_gid {
    my $self = shift;
    my $gids = shift // $self->{gids};
    return $self unless IS_ROOT; # Skip if no ROOT
    return $self unless defined $gids; # Skip if no GIDs

    # Get GIDs
    my $gid = (split /\s+/, $gids)[0]; # Get first GID
    $) = "$gid $gids"; # store all the GIDs (calls setgroups)
    POSIX::setgid($gid) || die "Setgid $gid failed - $!\n"; # Set first GID
    if (! grep {$gid == $_} split /\s+/, $() { # look for any valid id in the list
        die "Detected strange GID. Couldn't become GID \"$gid\": $!\n";
    }

    return $self;
}
sub daemonize {
    my $self = shift;
    my $safe = shift;
    croak "This process is already daemonized (PID=$$)\n" if $self->{daemonized};

    # Check PID
    my $pid_file = $self->filepid->file; # PID File
    if ( my $runned = $self->filepid->running ) {
        die "Already running $runned\n";
    }

    # Store current PID to instance as Parent PID
    $self->{ppid} = $$;

    # Get UID & GID
    my $uid = $self->{uid}; # UID
    my $gids = $self->{gid}; # returns list of groups (gids)
    my $gid = (split /[\s,]+/, $gids)[0]; # First GID
    _debug("!! UID=%s; GID=%s; GIDs=\"%s\"", $uid, $gid, $gids);

    # Pre Init Hook
    $self->preinit;
    $self->{_log} = undef; # Close log handlers before spawn

    # Spawn
    my $pid = _fork();
    if ($pid) {
        _debug("!! Spawned (PID=%s)", $pid);
        if ($safe) { # For internal use only
            $self->{pid} = $pid; # Store child PID to instance
            return $self;
        }
        exit 0; # exit parent process
    }

    # Child
    $self->{daemonized} = 1; # Set daemonized flag
    $self->filepid->pid($$)->save; # Set new PID and Write PID file
    chown($uid, $gid, $pid_file) if IS_ROOT && -e $pid_file;

    # Set GID and UID
    $self->set_gid->set_uid;

    # Turn process into session leader, and ensure no controlling terminal
    unless (DEBUG) {
        die "Can't start a new session: $!" if POSIX::setsid() < 0;
    }

    # Init logger!
    my $log = $self->log;

    # Close all standart filehandles
    unless (DEBUG) {
        my $devnull = File::Spec->devnull;
        open STDIN, '<', $devnull or die "Can't open STDIN from $devnull: $!\n";
        open STDOUT, '>', $devnull or die "Can't open STDOUT to $devnull: $!\n";
        open STDERR, '>&', STDOUT or die "Can't open STDERR to $devnull: $!\n";
    }

    # Chroot if root
    if (IS_ROOT) {
        my $rootdir = File::Spec->rootdir;
        unless (chdir $rootdir) {
            $log->fatal("Can't chdir to \"$rootdir\": $!");
            die "Can't chdir to \"$rootdir\": $!\n";
        }
    }

    # Clear the file creation mask
    umask 0;

    # Store current PID to instance
    $self->{pid} = $$;

    # Set a signal handler to make sure SIGINT's remove our pid_file
    $SIG{TERM} = $SIG{INT} = sub {
        POSIX::_exit(1) if $self->is_spirited;
        $self->cleanup(1);
        $log->fatal("Termination on INT/TERM signal");
        $self->filepid->remove;
        POSIX::_exit(1);
    };

    # Init Hook
    $self->init;

    return $self;
}
sub is_daemonized { shift->{daemonized} }
sub is_spirited { shift->{spirited} }
sub pid { shift->{pid} }

# Hooks
sub preinit { }
sub init { }
sub cleanup { } # 0 -- at destroy; 1 -- at interrupt
sub startup { }
sub hangup { }

# Process
sub flush { # Flush process counters
    my $self = shift;
    $self->{interrupt} = 0;
    $self->{signo} = 0;
    $self->{ok} = 1;
    return $self;
}
sub ok {
    my $self = shift;
    return 0 unless defined $self->{ppid}; # No parent pid found (it is not a daemon?)
    return $self->{ok} ? 1 : 0;
}

# LSB Daemon Control Methods
# These methods can be used to control the daemon behavior.
# Every effort has been made to have these methods DWIM (Do What I Mean),
# so that you can focus on just writing the code for your daemon
sub _term {
    my $self = shift;
    my $signo = shift || 0;
    $self->{ok} = 0; # Not Ok!
    $self->{signo} = $signo;
    $self->log->debug(sprintf("Request for terminate of ghost process %s received on signal %s", $self->pid, $signo));
    if ($self->{interrupt} >= INT_TRIES) { # Forced terminate
        POSIX::_exit(1) if $self->is_spirited;
        $self->cleanup(1);
        $self->log->fatal(sprintf("Ghost process %s forcefully terminated on signal %s", $self->pid, $signo));
        $self->filepid->remove;
        POSIX::_exit(1);
    }
    $self->{interrupt}++;
}
sub start {
    my $self = shift;
    $self->daemonize(1); # First daemonize and switch to child process
    return 0 unless $self->is_daemonized; # Exit from parent process

    # Signals Trapping for interruption
    local $SIG{INT}  = sub { $self->_term(SIGINT) };  # 2
    local $SIG{TERM} = sub { $self->_term(SIGTERM) }; # 15
    local $SIG{QUIT} = sub { $self->_term(SIGQUIT) }; # 3

    $self->flush; # Flush process counters
    $self->log->info(sprintf("Ghost process %s started", $self->pid));
    $self->startup(); # Master hook
    $self->log->info(sprintf("Ghost process %s stopped", $self->pid));
    exit 0; # Exit code for child: ok
}
sub stop {
    my $self = shift;
    my $pid = $self->filepid->running;
       $self->{pid} = $pid;
    return 0 unless $pid; # Not running

    # Try SIGQUIT ... 2s ... SIGTERM ... 4s ... SIGINT ... 3s ... SIGKILL ... 3s ... UNDEAD!
    my $tsig = 0;
    for ([SIGQUIT, 2], [SIGTERM, 2], [SIGTERM, 2], [SIGINT, 3], [SIGKILL, 3]) {
        my ($signo, $timeout) = @$_;
        kill $signo, $pid;
        for (1 .. $timeout) { # abort early if the process is now stopped
            unless ($self->filepid->running) {
                $tsig = $signo;
                last;
            }
            sleep 1;
        }
        last if $tsig;
    }
    if ($tsig) {
        if( $tsig == SIGKILL ) {
            $self->filepid->remove;
            warn "Had to resort to 'kill -9' and it worked, wiping pidfile\n";
        }
        return $pid;
    }

    # The ghost process doesn't seem to want to die. It is still running...;
    return -1 * $pid;
}
sub status {
    my $self = shift;
    return $self->{pid} = $self->filepid->running || 0;
}
sub restart {
    my $self = shift;
    my $runned = $self->stop;
    return 1 if $runned && $runned < 0; # It is still running
    _sleep(1); # delay before starting
    $self->start;
}
sub reload {
    my $self = shift;
    my $signo = shift // SIGHUP;
    $self->{pid} = $self->filepid->running || 0;
    return $self->start unless $self->pid; # Not running - start!
    kill $signo, $self->pid;
    return 0;
}
sub ctrl { # Dispatching
    my $self = shift;
    my $cmd = shift || '';
    my $sig = shift; # SIGHUP
    unless (grep {$cmd eq $_} @{(LSB_COMMANDS)}) {
        print STDERR "Command incorrect\n";
        return 1;
    }
    my $exit_code = 0; # Ok
    if ($cmd eq 'start') {
        $exit_code = $self->start;
        printf "Running %s\n", $self->pid;
    } elsif ($cmd eq 'status') {
        if (my $runned = $self->status) {
            printf "Running %s\n", $runned;
        } else {
            print "Not running\n";
        }
    } elsif ($cmd eq 'stop') {
        if (my $runned = $self->stop) {
            if ($runned < 0) {
                printf STDERR "The ghost process %s doesn't seem to want to die. It is still running...\n", $self->pid;
                $exit_code = 1;
            } else {
                printf "Stopped %s\n", $runned;
            }
        } else {
            print "Not running\n";
        }
    } elsif ($cmd eq 'restart') {
        $exit_code = $self->restart;
        if ($exit_code) {
            printf STDERR "Restart failed %s\n", $self->pid;
        } else {
            print "Restart successful\n";
        }
    } elsif ($cmd eq 'reload') {
        $exit_code = $self->reload($sig);
        printf "Reloading %s\n", $self->pid;
    }
    return $exit_code;
}

sub DESTROY {
    my $self = shift;
    return unless $self;
    return unless $self->{daemonized};
    return if $self->{spirited}; # Skip cleanup if it is spirit
    $self->cleanup(0);
    $self->filepid->remove;
}

# Utils
sub _sleep {
    my $delay = pop || SLEEP;
    sleep 1 for (1..$delay);
    return 1
}
sub _fork { # See Proc::Daemon::Fork
    my $lpid;
    my $loop = 0;

    # Block signal for fork
    my $sigset = POSIX::SigSet->new(SIGINT);
    POSIX::sigprocmask(SIG_BLOCK, $sigset) or die "Can't block SIGINT for fork: $!\n";

    MYFORK: {
        $lpid = fork;
        if (defined($lpid)) {
            $SIG{'INT'} = 'DEFAULT'; # make SIGINT kill us as it did before
            POSIX::sigprocmask(SIG_UNBLOCK, $sigset) or die "Can't unblock SIGINT for fork: $!\n";
            return $lpid;
        }
        if ( $loop < 6 && ( $! == POSIX::EAGAIN() ||  $! == POSIX::ENOMEM() ) ) {
            $loop++;
            _sleep(2);
            redo MYFORK;
        }
    }

    die "Can't fork: $!\n";
}
sub _debug {
    return unless DEBUG;
    my $message = (scalar(@_) == 1) ? shift(@_) : sprintf(shift(@_), @_);
    print STDERR $message, "\n";
}

1;

__END__
