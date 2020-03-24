package CTK::Daemon; # $Id: Daemon.pm 277 2020-03-22 18:09:31Z minus $
use strict;
use utf8;

=encoding utf8

=head1 NAME

CTK::Daemon - Abstract class to implement Daemons

=head1 VERSION

Version 1.04

=head1 SYNOPSIS

    use base qw/CTK::Daemon/;

    sub new {
        my $class = shift;
        # ... your code ...
        $class->SUPER::new(shift, @_);
    }

    sub run {
        my $self = shift;
        my $logger = $self->logger;
        $logger->log_info("Code is running");

        my $step = 5;
        while ($self->ok) { # Check it every time

            # If occurred usual error:
            #    $logger->log_error("...");
            #    mysleep SLEEP;
            #    next;

            # If occurred exception error
            #    $logger->log_crit("...");
            #    $self->exception(1);
            #    last;

            # For skip this loop
            #    $self->skip(1);
            #    next;

            last unless $self->ok; # Check it every time (after loop too)
        } continue {
            CTK::Daemon::mysleep $step if $step; # Delay! For avoid fast restarts
        }

        return 1;
    }

=head1 DESCRIPTION

Abstract class to implement Daemons

=head2 FEATURES

=over 8

=item *

Write PID file /var/run/$name.pid to make sure only one instance is running.

=item *

Correctly daemonize (redirect STDIN/STDOUT)

=item *

Restart by stop/start, exec, or signal HUP

=item *

Daemon restart on error

=item *

Handle worker processes

=item *

Run as different user using setuid/setgid

=back

=head2 METHODS

=over 8

=item new

    my $daemon = new CTK::Daemon('testdaemon', (
        ctk         => CTK::App->new(...), # Or create CTKx instance first
        debug       => 1, # Default: 0
        loglevel    => "debug", # Default: undef
        forks       => 3, # Default: 1
        uid         => "username", # Default: undef
        gid         => "groupname", # Default: undef
    ));

Daemon constructor

=item ctk, get_ctk

    my $ctk = $daemon->get_ctk;

Returns CTK object

=item ctrl

    exit ctrl( shift @ARGV ); # start, stop, restart, reload, status

LSB Control handler. Dispatching

=item logger

    my $logger = $daemon->logger;

Returns logger object

=item logger_close

    $daemon->logger_close;

Destroy logger

=item exit_daemon

    $self->exit_daemon(0);
    $self->exit_daemon(1);

Exit with status code

=item init, down, run

Base methods for overwriting in your class.

The init() method is called at startup - before forking

The run() method is called  at inside process and describes body of the your code

The down () method is called at cleanup - after processing

=item start, stop, restart, status and hup

LSB methods. For internal use only

=item exception

    $exception = $self->exception;
    $self->exception(exception);

Gets/Sets exception value

=item hangup

    $hangup = $self->hangup;
    $self->hangup($hangup);

Gets/Sets hangup value

=item interrupt

    $interrupt = $self->interrupt;
    $self->interrupt($interrupt);

Gets/Sets interrupt value

=item skip

    $skip = $self->skip;
    $self->skip($skip);

Gets/Sets skip value

=item ok

    sub run {
        my $self = shift;
        my $logger = $self->logger;
        $logger->log_info("Code is running");

        my $step = 5;
        while ($self->ok) { # Check it every time

            # If occurred usual error:
            #    $logger->log_error("...");
            #    mysleep SLEEP;
            #    next;

            # If occurred exception error
            #    $logger->log_crit("...");
            #    $self->exception(1);
            #    last;

            # For skip this loop
            #    $self->skip(1);
            #    next;

            last unless $self->ok; # Check it every time (after loop too)
        } continue {
            CTK::Daemon::mysleep $step if $step; # Delay! For avoid fast restarts
        }

        return 1;
    }

Checks worker's state and allows next iteration in main loop

=item reinit_worker

ReInitialize worker

=item worker

Internal use only

=item mysleep

    mysleep(5);

Provides safety delay

=item myfork

    my $pid = myfork;

Provides safety forking

=back

=head1 EXAMPLE

Classic example:

    package My::App;

    my $ctk = new CTK::App;
    my $daemon = new My::Class('testdaemon', (
        ctk         => $ctk,
        debug       => 1,
        loglevel    => "debug",
        forks       => 3,
    ));
    my $status = $daemon->ctrl("start");
    $daemon->exit_daemon($status);

    1;

    package My::Class;

    use base qw/CTK::Daemon/;

    sub new {
        my $class = shift;
        # ... your code ...
        $class->SUPER::new(shift, @_);
    }

    sub run {
        my $self = shift;
        my $logger = $self->logger;
        $logger->log_info("Code is running");

        my $step = 5;
        while ($self->ok) { # Check it every time

            # If occurred usual error:
            #    $logger->log_error("...");
            #    mysleep SLEEP;
            #    next;

            # If occurred exception error
            #    $logger->log_crit("...");
            #    $self->exception(1);
            #    last;

            # For skip this loop
            #    $self->skip(1);
            #    next;

            last unless $self->ok; # Check it every time (after loop too)
        } continue {
            CTK::Daemon::mysleep $step if $step; # Delay! For avoid fast restarts
        }

        return 1;
    }

    1;

AnyEvent example (better):

    package My::Class;

    use base qw/CTK::Daemon/;
    use AnyEvent;

    sub run {
        my $self = shift;
        my $logger = $self->logger;
        my $quit_program = AnyEvent->condvar;

        # Create watcher timer
        my $watcher = AnyEvent->timer (after => 3, interval => 3, cb => sub {
            $quit_program->send unless $self->ok;
        });

        # Create process timer
        my $timer = AnyEvent->timer(after => 3, interval => 15, cb => sub {
            $quit_program->send unless $self->ok;

            $logger->log_info("[%d] Worker is running #%d", $self->{workerident}, $self->{workerpid});

        });

        # Run!
        $quit_program->recv;

        return 1;
    }

    1;

=head1 HISTORY

=over 8

=item B<1.00 Mon Feb 27 12:33:51 2017 GMT>

Init version

=item B<1.01 Mon 13 May 19:53:01 MSK 2019>

Moved to CTKlib project

=back

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<POSIX>, L<Sys::Syslog>, L<Try::Tiny>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<POSIX>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

Based on PVE::Daemon ideology

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw/$VERSION @EXPORT $DEV_DEBUG/;
$VERSION = '1.04';

use Carp;
use File::Spec;
use POSIX qw/ :sys_wait_h /;
use Try::Tiny;
use Sys::Syslog ();

use CTKx;
use CTK::Util qw/ :API :CORE /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::FilePid;
use CTK::Log;

use base qw/Exporter/;

use constant {
    SLEEP       => 60,
    STEP        => 5,
    TRIES       => 3,
    KILL_TIMEOUT=> 3, # For killing
    FORKS       => 1,
    MIN_FORKS   => 1,
    MAX_FORKS   => 255,
    LSB_COMMANDS=> [qw/start stop reload restart status/],
    SIGS_DEF    => {
            HUP     => undef,
            TERM    => undef,
            INT     => undef,
            KILL    => undef,
            QUIT    => undef,
        },
};

@EXPORT = (qw/
        mysleep myfork
    /);

$DEV_DEBUG = 0;

sub mysleep;

my $daemon_initialized = 0; # we only allow one instance

my %LOCAL_SIG;
my $sigproxy = sub { $LOCAL_SIG{shift(@_)} = 1; };

sub new {
    my $class = shift;
    my $name = shift; # Should not happen
    my %params = @_;

    # Check instance
    die "Can't create more that one Daemon\n" if $daemon_initialized;
    $daemon_initialized = 1;

    # Check name
    die "Can't create unnamed daemon\n" unless $name;
    die "Incorrect daemon name: \"$name\"\n" unless $name =~ /[a-z0-9\-_.]+/i;

    # Check root permissions
    die "Please run as root\n" if $> != 0;

    my $ctk = $params{ctk} || CTKx->instance->ctk;
    die "CTK object required\n" unless $ctk && ref($ctk);

    my $forkers = $params{forks} || FORKS;
       $forkers = MAX_FORKS if $forkers > MAX_FORKS;
       $forkers = MIN_FORKS if $forkers < MIN_FORKS;
    my $pidfile = File::Spec->catfile(rundir(), sprintf("%s.pid", $name));
    my $pidf    = new CTK::FilePid({ file => $pidfile });
    my $pidstat = $pidf->running || 0;
    my $sigs    = SIGS_DEF;
       %LOCAL_SIG = %$sigs;
    my $loglevel = $params{loglevel};
    unless (defined($loglevel)) {
        $loglevel = $ctk->conf("loglevel") if $ctk->can("conf");
    }
    my $debug = $params{debug} // $ctk->debugmode;
    my $logger;

    # Stopping processes (LSB)
    my $lsbstop = sub {
        if ($pidstat) {
            foreach my $sg (qw(TERM TERM INT KILL)) {
                $logger->log_debug("Sending $sg signal to pid $pidstat..." ) if $logger;
                kill $sg => $pidstat;
                for (1..KILL_TIMEOUT)
                {
                    # abort early if the process is now stopped
                    $logger->log_debug("Checking if pid $pidstat is still running...") if $logger;
                    last unless $pidf->running;
                    sleep 1;
                }
                last unless $pidf->running;
            }
            if ( $pidf->running ) {
                warn("Failed to Stop");
                $logger->log_warn("Failed to Stop") if $logger;
                return 1;
            }
            my $tpid = $pidf->_get_pid_from_file;
            unlink($pidfile) if $tpid && (-e $pidfile) && $pidstat == $tpid;
            print("Stopped\n");
            $logger->log_info("Stopped") if $logger;
        } else {
            print("Not Running\n");
            $logger->log_info("Not Running") if $logger;
        }
        $pidstat = 0;
        return 0;
    };

    # Reloading processes (LSB)
    my $lsbreload = sub {
        if ($pidstat) {
            kill "HUP" => $pidstat;
            print("Reloaded\n");
            $logger->log_info("Reloaded") if $logger;
        } else {
            print("Not Running\n");
            $logger->log_info("Not Running") if $logger;
        }
        return 0;
    };

    # Get status (LSB)
    my $lsbstatus = sub {
        if ($pidstat) {
            print("Running\n");
            $logger->log_info("Running") if $logger;
        } else {
            print("Not Running\n");
            $logger->log_info("Not Running") if $logger;
        }
        return 0;
    };

    my $self = bless {
        name        => $name,
        ctk         => $ctk,
        ppid        => 0,
        pidfile     => $pidfile,
        initpid     => $$,
        initpidf    => $pidf,
        initpidstat => $pidstat, # From pid file!
        masterpid   => undef,
        workerpid   => undef,
        workerident => undef,
        sigs        => $sigs,
        gid         => $params{gid} || undef,
        uid         => $params{uid} || undef,
        forkers     => $forkers,

        debug       => $debug,
        loglevel    => $loglevel,
        logger      => undef,
        socketopts  => $params{socketopts},
        syslogopts  => $params{syslogopts},

        lsbstop     => $lsbstop,
        lsbreload   => $lsbreload,
        lsbstatus   => $lsbstatus,

        # General properties
        interrupt   => 0, # For common interruption only
        exception   => 0, # For exceptions
        hangup      => 0, # For reloading
        skip        => 0, # For skipping of subprocesses
    }, $class;

    $logger = $self->logger();

    return $self;
}

#
# General methods
#

sub worker {
    my $self = shift;
    my $logger = $self->logger;
    my $j = $self->{workerident} || 0;
    $self->{ppid} = _getppid();

    # Signals Trapping for worker-proccess interruption
    my $anon = sub {
        if ($self->interrupt >= TRIES) {
            $logger->log_crit("Can't terminate worker #%d pid=%d", $j, $$) if $logger;
            die(sprintf("Can't terminate worker #%d pid=%d\n", $j, $$));
        }
        $self->{interrupt}++;
    };
    local $SIG{TERM} = $anon;
    local $SIG{INT} = $anon;
    local $SIG{QUIT} = $anon;
    local $SIG{KILL} = $anon;
    local $SIG{HUP} = sub {$self->{hangup}++};

    $logger->log_info("Start worker #%d pid=%d", $j, $$) if $logger;
    RELOAD: if ($self->hangup) {
        $self->reinit_worker();
        $self->hangup(0);
    }

    my $status;
    eval { $status = $self->run(); };
    if (my $err = $@) {
        $self->hangup(1);
        $logger->log_error($err) if $logger;
        mysleep(STEP); # avoid fast restarts
    }
    if (!$status) { # Abort
        $logger->log_info("Abort worker #%d pid=%d (finished with negative status)", $j, $$) if $logger;
        return 1; # For exit!
    } elsif ($self->exception) { # Exceptions
        if ($logger) {
            $logger->log_crit("Exception #%d pid=%d", $j, $$);
        } else {
            printf STDERR "Exception #%d pid=%d\n", $j, $$;
        }
        return 1; # For exit!
    } elsif ($self->interrupt) { # Interruption
        if ($logger) {
            $logger->log_error("Interrupt worker #%d pid=%d", $j, $$);
        } else {
            printf STDERR "Interrupt worker #%d pid=%d\n", $j, $$;
        }
        return 1; # For exit!
    } elsif ($self->hangup) { # Reloading
        $logger->log_info("Reload worker #%d pid=%d", $j, $$) if $logger;
        goto RELOAD;
    }

    $logger->log_info("Finish worker #%d pid=%d", $j, $$) if $logger;
    return 0; # For exit!
}

# Control handler. Dispatching
sub ctrl {
    my $self = shift;
    my $cmd = shift || '';

    # LSB kill's process (signal)
    if ($cmd eq 'start') {
        # NOOP
    } elsif ($cmd eq 'restart') {
        return $self->restart();
    } elsif ($cmd eq 'stop') {
        return $self->stop();
    } elsif ($cmd eq 'reload') {
        return $self->hup();
    } elsif ($cmd eq 'status') {
        return $self->status();
    } else {
        printf STDERR "Command incorrect. Supported: %s\n", join(", ", @{LSB_COMMANDS()});
        return 0;
    }

    # Starting
    if (my $pidstat = $self->{initpidstat}) {
        printf STDERR "Daemon already started (pid=%d; file=%s)\n", $pidstat, $self->{initpidf}->file();
    } else {
        return $self->start();
    }
    return 0;
}

# CTK object getters
sub get_ctk {
    my $self = shift;
    return $self->{ctk};
}
sub ctk { goto &get_ctk }

#
# Methods for overwriting in user class
#

# Please overwrite in subclass
#  this is called at startup - before forking
sub init {
    my $self = shift;
    return 1;
}
# Please overwrite in subclass
#  this is called at cleanup - after processing
sub down {
    my $self = shift;
    return 1;
}
# Please overwrite in subclass
sub run {
    my $self = shift;
    return 1;
}

#
# LSB methods
#

sub start {
    my $self = shift;
    my $logger = $self->logger;

    # Load GID and UID
    my ($uid, $gid);
    if (my $uidstr = $self->{uid}) {
        $uid = getpwnam($uidstr) || croak "getpwnam failed - $!\n";
    }
    if (my $gidstr = $self->{gid}) {
        $gid = getgrnam($gidstr) || croak "getgrnam failed - $!\n";
    }

    # PidFile prepare
    if (defined($uid) or defined($gid)) {
        my $pidfile = $self->{pidfile};
        unless (-e $pidfile) {
            CTK::Util::fsave($pidfile, "0\n");
            chown($uid, $gid, $pidfile) if -e $pidfile;
        }
    }

    # Set GID and UID
    if (defined($gid)) {
        POSIX::setgid($gid) || croak "setgid $gid failed - $!\n";
        $) = "$gid $gid"; # this calls setgroups
        croak "detected strange gid\n" if !($( eq "$gid $gid" && $) eq "$gid $gid"); # just to be sure
    }
    if (defined($uid)) {
        POSIX::setuid($uid) || croak "setuid $uid failed - $!\n";
        croak "detected strange uid\n" if !($< == $uid && $> == $uid); # just to be sure
    }

    my $save_pid = $$;
    #say "PID> $$";
    #say "INITPID> ".$self->{initpid};
    my $pidf = $self->{initpidf};

    $self->init();

    # Start master process
    my $pid = myfork();
    print("Started\n") if $pid;
    if ($pid && $self->{debug}) {
        #printf("Master process (pid=%d) successfully started\n", $pid);
        $logger->log_debug("Master process (pid=%d) successfully started", $pid) if $logger;
    }
    $self->logger_close;

    if ( defined($pid) && $pid == 0 ) { # The master child runs here.
        $pidf->pid(isostype('Windows') ? $save_pid : $$);
        $self->{masterpid} = $pidf->pid;
        $pidf->write;

        # Detach the child from the terminal (no controlling tty), make it the
        # session-leader and the process-group-leader of a new process group.
        unless ($DEV_DEBUG || isostype('Windows')) {
            die "Can't detach from controlling terminal" if POSIX::setsid() < 0;
        }

        # Catching the signals
        $SIG{$_} = $sigproxy for keys %LOCAL_SIG;
        $self->{sigs} = {%LOCAL_SIG};
        #say Dumper($self);


        # Second fork. See Proc::Daemon
        my (@pids, %pidh);
        for (my $j = 1; $j <= $self->{forkers}; $j++) {
            my $cpid = myfork();
            if ( defined($cpid) && $cpid == 0 ) { # Here the second child is running.
                # Close all file handles and descriptors the user does not want to preserve.
                my $devnull = File::Spec->devnull;
                unless ($DEV_DEBUG || ($self->{debug} && isostype('Windows'))) {
                    open( STDIN, "<", $devnull ) or die "Failed to open STDIN to $devnull: $!";;
                    open( STDOUT, ">>", $devnull ) or die "Failed to open STDOUT to $devnull: $!";
                    open( STDERR, ">>", $devnull ) or die "Failed to open STDERR to $devnull: $!";
                }

                # CODE
                $self->{workerpid} = $$;
                $self->{workerident} = $j;
                my $status = $self->worker();
                $self->down();
                exit $status;
            }

            # First child (= second parent) runs here.
            if ($cpid) {
                $pidh{$cpid} = 0;
            }
        }

        # For master process (signals proxying)
        while (grep {$_ == 0} values %pidh) {
            @pids = grep {$pidh{$_} == 0} keys %pidh;
            foreach my $k (grep {$LOCAL_SIG{$_}} keys %LOCAL_SIG) {
                foreach my $p (@pids) {
                    print "==> Send $k signal to $p\n" if $self->{debug};
                    kill $k => $p;
                }
                $LOCAL_SIG{$k} = 0;
            }
            foreach my $p (@pids) {
                $pidh{$p} = 1 if waitpid $p, WNOHANG;
            }
        } continue {
            sleep 1;
        }
        #print("Terminated!\n");


        if ($self->{debug}) {
            #printf("Master process (pid=%d) successfully finished\n", $$);
            $self->logger->log_info("Master process (pid=%d) successfully finished", $$) if $self->logger;
        }
        $pidf->remove;
        POSIX::_exit(0);
    }

    return 0;
}
sub stop {
    my $self = shift;
    my $lsbstop = $self->{lsbstop};
    return &$lsbstop();
}
sub restart {
    my $self = shift;
    $self->stop();

    my $pidf = new CTK::FilePid({ file => $self->{pidfile} });
    $self->{initpid} = $$;
    $self->{initpidf} = $pidf;
    $self->{initpidstat} = $pidf->running || 0;

    return $self->start();
}
sub status {
    my $self = shift;
    my $lsbstatus = $self->{lsbstatus};
    return &$lsbstatus();
}
sub hup {
    my $self = shift;
    my $lsbreload = $self->{lsbreload};
    $self->logger->log_info("Received signal HUP (reload)") if $self->logger;
    return &$lsbreload();
}

#
# Helper methods
#

sub logger {
    my $self = shift;
    return $self->{logger} if $self->{logger};
    my $ctk = $self->{ctk};
    return $ctk->logger if $ctk && $ctk->can("logger") && $ctk->logger;
    my $logger = new CTK::Log(
        level => $self->{loglevel},
        ident => $self->{name},
        facility => Sys::Syslog::LOG_DAEMON,
        socketopts => $self->{socketopts},
        syslogopts => $self->{syslogopts},
    );
    $self->{logger} = $logger;
    return $logger;
}
sub logger_close {
    my $self = shift;
    undef $self->{logger};
    return 1;
}
sub exit_daemon {
    my $self = shift;
    my $status = shift;
    exit($status);
}

#
# Utility methods
#

sub mysleep {
    my $delay = shift || SLEEP;
    foreach (1..$delay) {
        sleep 1
    }
    return 1
}
sub myfork { # See Proc::Daemon::Fork
    my $lpid;
    my $loop = 0;

    FORK: {
        $lpid = fork;
        return $lpid if defined($lpid);
        if ( $loop < 6 && ( $! == POSIX::EAGAIN() ||  $! == POSIX::ENOMEM() ) ) {
            $loop++; sleep 5;
            redo FORK;
        }
    }

    warn "Can't fork: $!";
    return undef;
}

#
# Process methods
#

sub reinit_worker {
    my $self = shift;
    $self->interrupt(0);
    $self->exception(0);
    $self->hangup(0);
    $self->skip(0);
    return 1;
}
sub interrupt {
    my $self = shift;
    my $v = shift;
    $self->{interrupt} = $v if defined($v);
    return $self->{interrupt} || 0;
}
sub exception {
    my $self = shift;
    my $v = shift;
    $self->{exception} = $v if defined($v);
    return $self->{exception} || 0;
}
sub hangup {
    my $self = shift;
    my $v = shift;
    $self->{hangup} = $v if defined($v);
    return $self->{hangup} || 0;
}
sub skip {
    my $self = shift;
    my $v = shift;
    $self->{skip} = $v if defined($v);
    return $self->{skip} || 0;
}
sub ok {
    my $self = shift;
    my $ppid = shift // $self->{ppid};
    return 0 unless defined $ppid;
    $self->exception(1) if $ppid != _getppid();
    return 0 if $self->exception || $self->interrupt || $self->hangup || $self->skip;
    return 1;
}

sub _getppid {
    return 0 if isostype('Windows');
    POSIX::getppid();
}

1;
