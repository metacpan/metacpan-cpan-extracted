package Beekeeper::WorkerPool::Daemon;

use strict;
use warnings;

our $VERSION = '0.05';

use POSIX;
use Fcntl qw(:DEFAULT :flock);
use Getopt::Long;

my $PID_FILE_DIR = "/var/run";
my $LOG_FILE_DIR = "/var/log";


sub new {
    my $class = shift;
    my $self = {
        options    => {},
        config     => {},
        daemonized => 0,
    };
    bless $self, $class;
    $self->configure(@_);
    return $self;
}

sub configure {
    my ($self, %config) = @_;
    foreach (keys %config) {
        $self->{config}->{$_} = $config{$_};
    }
}

sub config {
    my ($self, $key) = @_;
    $self->{config}->{$key};
}

sub parse_options {
    my $self = shift;

    # Parse command line options using Getopt::Long

    my @options_spec = ( "foreground", "user=s", "group=s", "help" );

    my $extra_options = $self->{config}->{get_options};
    if ($extra_options) {
        foreach my $opt (@$extra_options) {
            next if (grep { $opt eq $_ } @options_spec);
            push @options_spec, $opt;
        }
    }

    # GetOptions cannot be done twice
    return if keys %{$self->{options}};

    my %options;
    GetOptions(\%options, @options_spec) or CORE::exit(1);
    $self->{options} = \%options;
}

sub option {
    my ($self, $option) = @_;
    $self->{options}->{$option};
}

sub daemon_name {
    my $self = shift;
    my $daemon_name = $self->{config}->{daemon_name};
    unless ($daemon_name) {
        $daemon_name = $0;
        $daemon_name =~ s|.*/||;
    }
    return $daemon_name;
}

sub daemon_description {
    my $self = shift;
    $self->{config}->{description} || 'daemon';
}


#------------------------------------------------------------------------------

sub run {
    my $self = shift;

    $self->parse_options;

    my $cmd = $ARGV[0];

    $cmd = 'help' if (!$cmd || $self->{options}->{help});

    if ($cmd eq 'start') {
        $self->cmd_start;
        #goto &cmd_start;
    }
    elsif ($cmd eq 'stop') {
        $self->cmd_stop;
    }
    elsif ($cmd eq 'restart') {
        $self->cmd_stop;
        $self->cmd_start;
        #goto &cmd_start;
    }
    elsif ($cmd eq 'reload') {
        $self->cmd_reload;
    }
    elsif ($cmd eq 'check') {
        $self->cmd_check;
    }
    elsif ($cmd eq 'help') {
        $self->cmd_help;
    }
    else {
        print "Unknown command '$cmd'.\n";
        $self->cmd_help;
    }
}

sub cmd_start {
    my $self = shift;

    print "Starting " . $self->daemon_description . ": " . $self->daemon_name;

    if ($self->daemon_is_running) {
        print " is already running.\n";
        return;
    }

    print ".\n" if ($self->{options}->{foreground});

    $self->daemonize;
    #goto &daemonize;

    print ".\n";
}

sub cmd_stop {
    my $self = shift;

    print "Stopping " . $self->daemon_description . ": " . $self->daemon_name;

    unless ($self->daemon_is_running) {
        print " was not running.\n";
        return;
    }

    $self->stop_daemon;
    print ".\n";
}

sub cmd_reload {
    my $self = shift;

    print "Reloading " . $self->daemon_description . ": " . $self->daemon_name;

    $self->hup_daemon;
    print ".\n";
}

sub cmd_check {
    my $self = shift;

    print $self->daemon_name;

    if ($self->daemon_is_running) {
        print " is running.\n";
    }
    else {
        print " is not running.\n";
    }
}

sub cmd_help {
    my $self = shift;

    my $progname = $0;
    $progname =~ s|.*/||;

    print "Usage: $progname [options] {start|stop|restart|reload|check}\n";
    print " --foreground  Run in foreground (do not daemonize)\n";
    print " --user        Run as specified user\n";
    print " --group       Run as specified group\n";
    print " --help        Shows this message\n";
}


#------------------------------------------------------------------------------

# DAEMONIZE

sub daemonize {
    my $self = shift;

    unless ($self->{options}->{foreground}) {

        # Fork and exit parent
        _fork() && return;

        # Detach ourselves from the terminal
        POSIX::setsid() or die("Cannot detach from controlling terminal");

        # Prevent possibility of acquiring a controling terminal
        $SIG{'HUP'} = 'IGNORE';
        _fork() && CORE::exit(0);

        # Change working directory
        chdir "/";

        # Clear file creation mask
        umask 0;

        # Close open file descriptors
        my $openmax = POSIX::sysconf( &POSIX::_SC_OPEN_MAX );
        $openmax = 64 if (!defined($openmax) || $openmax < 0);
        foreach my $i (0..$openmax) { POSIX::close($i); }

        $self->redirect_output;

        $self->{daemonized} = 1;
    }

    $self->write_pid_file;

    $self->change_effective_user;

    $self->main;

    CORE::exit(0);
}

sub _fork {
    FORK: {
        if (defined(my $pid = fork())) {
            return $pid;
        }
        elsif ($! =~ /No more process/) {
            sleep(5);
            redo FORK;
        }
        else {
            die("Can't fork: $!");
        }
    }
}


sub redirect_output {
    my $self = shift;

    my $logfile = $self->{config}->{logfile};

    unless ($logfile) {
        my $dir  = $LOG_FILE_DIR;
        my $user = getpwuid($<);
        my $file = $self->daemon_name . '.log';
        $logfile = (-d "$dir/$user") ? "$dir/$user/$file" : "$dir/$file";
    }

    die unless ($logfile =~ m/\.log$/);

    open(LOG, '>>', $logfile) or die("Can't open log file '$logfile': $!");

    open(STDERR, '>&', \*LOG)     or (print "Can't redirect STDERR to log file: $!" && CORE::exit(1));
    open(STDOUT, '>&', \*LOG)     or die("Can't redirect STDOUT to log file: $!");
    open(STDIN, '<', '/dev/null') or die("Can't reopen STDIN to /dev/null: $!");

    # Autoflush after each write
    $| = 1;
}


sub change_effective_user {
    my $self = shift;

    # Note that privileges are not permanently dropped and can be restored.
    # If you need to drop privileges permanently, override this method and
    # use the module Unix::SetUser which allows to do that (or think about
    # using 'su' to start your daemon as a non root user)

    # Only root can swith user
    return unless ($> == 0);

    my $as_user  = $self->{options}->{user}  || "nobody";
    my $as_group = $self->{options}->{group} || "nogroup";

    my $uid = getpwnam($as_user);
    my $gid = getgrnam($as_group);

    unless (defined $uid) {
        die("Cannot switch to a non existent user '$as_user'");
    }
    unless (defined $gid) {
        die("Cannot switch to a non existent group '$as_group'");
    }
    unless ($uid > 0) {
        die("Cannot run daemon as root");
    }

    # Change the effective gid
    $) = $gid  or die("Cannot switch to group '$as_group': $!");

    # Change the effective uid
    $> = $uid  or die("Cannot switch to user '$as_user': $!");
}

sub restore_effective_user {
    my $self = shift;

    # Only root can swith user
    return unless ($< == 0);
 
    # Restore the effective uid to the real uid
    $> = $<;

    # Restore the effective gid to the real gid
    $) = $(;
}


#------------------------------------------------------------------------------

# PIDFILE HANDLING

sub pid_file {
    my $self = shift;

    my $pidfile = $self->{config}->{pidfile};

    unless ($pidfile) {
        my $dir  = $PID_FILE_DIR;
        my $user = getpwuid($<);
        my $file = $self->daemon_name . '.pid';
        $pidfile = (-d "$dir/$user") ? "$dir/$user/$file" : "$dir/$file";
    }

    return $pidfile;
}

sub write_pid_file {
    my $self = shift;
    my $pidfile = $self->pid_file;

    die unless ($pidfile =~ m/\.pid$/);

    # Open the pidfile in exclusive mode, to avoid race conditions
    sysopen(my $fh, $pidfile, O_RDWR|O_CREAT)  or die("Cannot open pid file '$pidfile': $!");
    flock($fh, LOCK_EX | LOCK_NB)              or die("Pid file '$pidfile' is already locked");

    # Read the content of the pidfile
    my $pid = <$fh>;

    if ($pid && $pid =~ m/^(\d+)/ && $pid != $$) {
        # File already exists and contains a process id. Check then if that 
        # process id actually belong to a running instance of this daemon
        if ($self->verify_daemon_process($pid)) {
            close($fh);
            die("Cannot write pid file: alredy running");
        }
    }

    # Write our process id to the file
    sysseek($fh, 0, 0)                     or die("Cannot seek in pid file '$pidfile': $!");
    truncate($fh, 0)                       or die("Cannot truncate pid file '$pidfile': $!");
    syswrite($fh, "$$\n", length("$$\n"))  or die("Cannot write to pid file '$pidfile': $!");
    close($fh);
}

sub read_pid_file {
    my $self = shift;
    my $pidfile = $self->pid_file;

    unless (-e $pidfile) {
        # Pidfile does not exists
        return;
    }

    # Read the content of the pidfile
    open(my $fh, '<', $pidfile) or die("Cannot open pid file '$pidfile': $!");
    my ($pid) = <$fh> =~ /^(\d+)/;
    close($fh);

    return $pid;
}

sub delete_pid_file {
    my $self = shift;

    my $pid = $self->read_pid_file;

    unless ($pid) {
        # Do not delete file, it does not exist or does not contain a process id
        return;
    }

    unless ($pid == $$) {
        # Do not delete file, it was not created by this process
        return;
    }

    my $pidfile = $self->pid_file;
    die unless ($pidfile =~ m/\.pid$/);
    unlink($pidfile) or warn("Cannot unlink pid file '$pidfile' : $!");
}

sub verify_daemon_process {
    my ($self, $pid) = @_;

    # Verify that the process identifed by the pid is actually running and
    # is an instance of this daemon. This is necessary because the process id 
    # written to the pidfile by an instance of the daemon may coincidentally 
    # be reused by another process after a system restart, thus making the 
    # daemon think it's already running and preventing it from start at boot
    # time. This implementation checks the 'ps' output.

    unless (kill(0, $pid)) {
        # Process is not running
        return 0;
    }

    unless ($^O =~ m/linux|freebsd/i) {
        # The ps verification will only work for Linux and FreeBSD
        return 1;
    }

    my $me = $0;
    $me =~ s|.*/||;

    die unless ($pid =~ m/^\d+$/); # paranoid security check
    my $ps_output = `ps -fp $pid` or die("ps utility not available: $!");

    my @ps_lines = split("$/", $ps_output);
    return 0 unless (scalar @ps_lines == 2);
    s/^\s+// foreach (@ps_lines); # trim leading spaces
    my @ps_header = split(/\s+/, $ps_lines[0]);
    my $columns_count = scalar @ps_header;
    my @ps_cols = split(/\s+/, $ps_lines[1], $columns_count);
    my $command = $ps_cols[$columns_count - 1]; # last column

    my $me_regex = quotemeta($me);
    return ($command =~ m/$me_regex/) ? 1 : 0;
}

sub daemon_is_running {
    my $self = shift;

    my $pid = $self->read_pid_file;

    # Daemon is not running if not pidfile exist
    return 0 unless ($pid);

    # Verify that the process identifed by the readed pid is actually
    # running and is an instance of this daemon
    return 0 unless ($self->verify_daemon_process($pid));

    return $pid;
}


#------------------------------------------------------------------------------

# PROCESS TERMINATION

sub stop_daemon {
    my $self = shift;

    my $pid = $self->daemon_is_running;

    # Nothing to do if daemon is not running
    return unless ($pid);

    my $send_SIGINT  = 15; # seconds
    my $send_SIGKILL = 30; # seconds
    my $give_up      = 90; # seconds

    my $start_time = time();
    local $| = 1;

    # Send SIGTERM (terminate request) signal
    if (kill( SIGTERM, $pid )) {
        WAIT: {
            sleep(1);
            return unless kill(0, $pid);
            my $elapsed = time() - $start_time;
            redo if ($elapsed < $send_SIGINT);
        }
    }

    # Send SIGINT (interrupt request) signal
    if (kill( SIGINT, $pid )) {
        print "\nSending SIGINT to process $pid...";
        WAIT: {
            sleep(1);
            return unless kill(0, $pid);
            my $elapsed = time() - $start_time;
            redo if ($elapsed < $send_SIGKILL);
        }
    }

    # Send SIGKILL (terminate immediately) signal
    if (kill( SIGKILL, $pid )) {
        print "\nSending SIGKILL to process $pid...";
        WAIT: {
            sleep(1);
            return unless kill(0, $pid);
            my $elapsed = time() - $start_time;
            redo if ($elapsed < $give_up);
        }
    }

    print "\nGiving up, cannot kill process $pid.\n";
    CORE::exit(1);
}

sub hup_daemon {
    my $self = shift;

    my $pid = $self->daemon_is_running;

    # Nothing to do if daemon is not running
    return unless ($pid);

    kill( SIGHUP, $pid );
}

sub DESTROY {
    my $self = shift;

    $self->restore_effective_user;

    $self->delete_pid_file;
}


#------------------------------------------------------------------------------

# main() method is intended to be overrided, this is just a placeholder

sub main {
    my $self = shift;

    print "\nStarted...\n";

    my $quit = 0;

    $SIG{'TERM'} = sub { $quit = 1 };  # SIGTERM  terminate request
    $SIG{'INT'}  = sub { $quit = 1 };  # SIGINT   interrupt request, Ctrl-C

    while (!$quit) {
        # Do something here...
        sleep 1;
    }

    print "Stopped\n";
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Beekeeper::WorkerPool::Daemon - Daemonize processes

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

  package MyDaemon;
  use base 'Beekeeper::WorkerPool::Daemon';
  
  sub main {
      my $self = shift;
      my $quit = 0;
  
      $SIG{'TERM'} = sub { $quit = 1 };
      $SIG{'INT'}  = sub { $quit = 1 };
  
      while (!$quit) {
          # Do something here...
          sleep 1;
      }
  }

Then, the daemon can be executed with a script like this:

  #!/usr/bin/perl -wT
  use strict;
  use warnings;
  use MyDaemon;
  
  $ENV{PATH} = '/bin'; # untaint
  
  my $daemon = MyDaemon->new->run;

=head1 DESCRIPTION

This is a base module for creating daemons. It takes care of daemonization tasks
commonly found in init.d scripts: forking, redirecting output, writing pid files, 
start/stop/restart control commands, etc.

It is used by the command line tool C<bkpr> to daemonize itself.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
