package App::Base::Daemon;
use 5.010;
use Moose::Role;
with 'App::Base::Script::Common';

our $VERSION = '0.08';    ## VERSION

=head1 NAME

App::Base::Daemon - A lazy person's tool for writing self-documenting, self-monitoring daemons

=head1 SYNOPSIS

    package App::Base::Daemon::example;
    use Moose;
    with 'App::Base::Daemon';
    sub documentation { return 'This is an example daemon.'; }

    sub options {

        # See App::Base::Script::Common
    }

    sub daemon_run {
        my $self = shift;
        while (1) {
            # do something
            sleep(1)
        }

        return 0;    # This will never be reached
    }

    sub handle_shutdown {
        my $self = shift;
        # do something
        return 0;
    }

    no Moose;
    __PACKAGE__->meta->make_immutable;
    1;

    exit App::Base::Daemon::example->new->run;

=head1 DESCRIPTION

App::Base::Daemon builds on App::Base::Script::Common and provides common infrastructure for writing daemons, including:

=over 4

=item -

Standardized logging techniques via syslog

=item -

Signal processing and graceful shutdown

=back

=head1 BUILT-IN OPTIONS

Every App::Base::Daemon-implementing class gets some daemon-specific options for
free, in addition to those provided by App::Base::Script::Common. They are:

=head2 --no-fork

Rather than double-forking and detaching from the console, the daemon
runs in the foreground (parent) process. Useful for debugging or
interactive invocations.

=head2 --pid-file

Writes PID of the daemon into specified file, by default writes pid into /var/run/__PACKAGE__.pid

=head2 --no-pid-file

Do not write pid file, and do not check if it is exist and locked.

=head2 --no-warn

Do not produce warnings, silent mode

=head1 REQUIRED SUBCLASS METHODS

=cut

use namespace::autoclean;
use Syntax::Keyword::Try;
use Path::Tiny;

=head2 daemon_run

The main loop that runs the daemon. Typically this will include while(1) or
something similar.  If this method returns, daemon exits.

=cut

requires 'daemon_run';

=head2 handle_shutdown

Called before the daemon shuts down in response to a shutdown signal. Should
clean up any resources in use by the daemon. The return value of
handle_shutdown is used as the exit status of the daemon.

=cut

requires 'handle_shutdown';

use Socket;
use IO::Handle;
use File::Flock::Tiny;
use POSIX qw();

=head1 ATTRIBUTES

=head2 shutdown_signals

An arrayref of signals that should result in termination of the daemon.
Defaults are: INT, QUIT, TERM.

=cut

has 'shutdown_signals' => (
    is      => 'ro',
    default => sub {
        [qw( INT QUIT TERM )];
    },
);

=head2 user

Run as specified user, note that it is only possible if daemon started as root

=cut

has user => (is => 'ro');

=head2 group

Run as specified group, note that it is only possible if daemon started as root

=cut

has group => (is => 'ro');

=head2 pid_file

Pid file name

=cut

has pid_file => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_pid_file',
);

sub _build_pid_file {
    my $self = shift;
    my $file = $self->getOption('pid-file');
    unless ($file) {
        my $class  = ref $self;
        my $piddir = $ENV{APP_BASE_DAEMON_PIDDIR} || '/var/run';
        $file = path($piddir)->child("$class.pid");
    }
    return "$file";
}

=head2 can_do_hot_reload

Should return true if implementation supports hot reloading

=cut

sub can_do_hot_reload { return }

around 'base_options' => sub {
    my $orig = shift;
    my $self = shift;
    return [
        @{$self->$orig},
        {
            name          => 'no-fork',
            documentation => "Do not detach and run in the background",
        },
        {
            name          => 'pid-file',
            option_type   => 'string',
            documentation => "Use specified file to save PID",
        },
        {
            name          => 'no-pid-file',
            documentation => "Do not check if pidfile exists and locked",
        },
        {
            name          => 'user',
            documentation => "User to run as",
        },
        {
            name          => 'group',
            documentation => "Group to run as",
        },
        {
            name          => 'no-warn',
            documentation => 'Do not produce warnings',
        },
    ];
};

=head1 METHODS

=cut

sub _signal_shutdown {
    my $self = shift;
    $self->handle_shutdown;
    exit 0;
}

sub __run {
    my $self = shift;

    my $pid;
    my $hot_reload = $ENV{APP_BASE_DAEMON_GEN}++ && $self->can_do_hot_reload;
    unless ($self->getOption('no-pid-file') or $hot_reload) {
        $pid = File::Flock::Tiny->trylock($self->pid_file);
        unless ($pid) {
            if ($self->can_do_hot_reload) {
                chomp(my $pid = eval { my $fh = path($self->pid_file)->openr; <$fh>; });
                if ($pid and kill USR2 => $pid) {
                    warn("Daemon is alredy running, initiated hot reload") unless $self->getOption('no-warn');
                    exit 0;
                } else {
                    $self->error("Neither could lock pid file nor send USR2 to already running daemon.");
                }
            } else {
                die("Couldn't lock " . $self->pid_file . ". Is another copy of this daemon already running?");
            }
        }
    }

    $SIG{PIPE} = 'IGNORE';    ## no critic (RequireLocalizedPunctuationVars)
    foreach my $signal (@{$self->shutdown_signals}) {
        $SIG{$signal} = sub { App::Base::Daemon::_signal_shutdown($self, @_) };    ## no critic (RequireLocalizedPunctuationVars)
    }

    # Daemonize unless specifically asked not to.
    unless ($self->getOption('no-fork') or $hot_reload) {
        my $child_pid = fork();
        if (!defined($child_pid)) {
            die("Can't fork child process: $!");
        } elsif ($child_pid == 0) {
            POSIX::setsid();
            my $grandchild_pid = fork();
            if (!defined($grandchild_pid)) {
                die("Can't fork grandchild process: $!");
            } elsif ($grandchild_pid != 0) {
                $pid->close if $pid;
                exit 0;
            } else {
                # close all STD* files, and redirect STD* to /dev/null
                for (0 .. 2) {
                    POSIX::close($_) unless $pid and $_ == $pid->fileno;
                }
                (open(STDIN, '<', '/dev/null') and open(STDOUT, '>', '/dev/null') and open(STDERR, '>', '/dev/null'))
                    or die "Couldn't open /dev/null: $!";
            }
        } else {
            waitpid($child_pid, 0);
            $pid->close if $pid;
            return $?;
        }
    }

    $self->_set_user_and_group unless $hot_reload;

    $pid->write_pid if $pid;

    my $result;
    try { $result = $self->daemon_run(@{$self->parsed_args}); }
    catch ($e) {
        $self->error($e);
    }

    undef $pid;

    return $result;
}

sub _set_user_and_group {
    my $self = shift;

    my $user  = $self->getOption('user')  // $self->user;
    my $group = $self->getOption('group') // $self->group;
    if ($user or $group) {
        if ($> == 0) {
            my ($uid, $gid) = (0, 0);
            if ($group) {
                $gid = getgrnam($group) or $self->error("Can't find group $group");
            }
            if ($user) {
                $uid = getpwnam($user) or $self->error("Can't find user $user");
            }
            if ($uid or $gid) {
                chown $uid, $gid, $self->pid_file;
            }
            if ($gid) {
                POSIX::setgid($gid);
            }
            if ($uid) {
                POSIX::setuid($uid);
            }
        } else {
            warn("Not running as root, can't setuid/setgid") unless $self->getOption('no-warn');
        }
    }

    return;
}

=head2 error

Handles the output of errors, including shutting down the running daemon by
calling handle_shutdown().  If you have a serious problem that should NOT
result in shutting down your daemon, use warn() instead.

=cut

sub error {    ## no critic (RequireArgUnpacking)
    my $self = shift;
    warn("Shutting down: " . join(' ', @_)) unless $self->getOption('no-warn');

    $self->handle_shutdown();
    return exit(-1);
}

no Moose::Role;
1;

__END__

=head1 USAGE

=head2 Inheritance

Invocation of a App::Base::Daemon-based daemon is accomplished as follows:

=over 4

=item -

Define a class that implements App::Base::Daemon

=item -

Instantiate an object of that class via new()

=item -

Run the daemon by calling run(). The return value of run() is the exit
status of the daemon, and should typically be passed back to the calling
program via exit()

=back

=head2 The new() method

(See App::Base::Script::Common::new)

=head2 Options handling

(See App::Base::Script::Common, "Options handling")

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010-2014 Binary.com

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
