package App::Daemon;
use strict;
use warnings;

our $VERSION = '0.22';

use Getopt::Std;
use Pod::Usage;
use File::Basename;
use Log::Log4perl qw(:easy);
use POSIX;
use Exporter;
use Fcntl qw/:flock/;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(daemonize cmd_line_parse detach);

use constant LSB_OK               => 0;
use constant LSB_DEAD_PID_EXISTS  => 1;
use constant LSB_DEAD_LOCK_EXISTS => 2;
use constant LSB_NOT_RUNNING      => 3;
use constant LSB_UNKNOWN          => 4;
use constant ALREADY_RUNNING      => 150;

our ($pidfile, $logfile, $l4p_conf, $as_user, $as_group, $background,
     $loglevel, $action, $appname, $default_pid_dir, $default_log_dir);
$action  = "";
$appname = appname();

$default_pid_dir = ".";
$default_log_dir = ".";

our $kill_retries = 3;
our $kill_sig = SIGTERM; # maps to 15 via POSIX.pm

###########################################
sub cmd_line_parse {
###########################################

    if( find_option("-h") ) {
        pod2usage();
    }

    if(my $_pidfile = find_option('-p', 1)) {
      $pidfile    = $_pidfile;
    }
    else {
      $pidfile  ||= ( "$default_pid_dir/" . $appname . ".pid" );
    }

    if(my $_logfile = find_option('-l', 1)) {
      $logfile    = $_logfile;
    }
    else {
      $logfile  ||= ( "$default_log_dir/" . $appname . ".log" );
    }

    if(my $_l4p_conf = find_option('-l4p', 1)) {
      $l4p_conf   = $_l4p_conf;
    }

    if(my $_as_user = find_option('-u', 1)) {
      $as_user    = $_as_user;
    }
    else {
      $as_user  ||= 'nobody';
    }

    if(my $_as_group = find_option('-g', 1)) {
      $as_group   = $_as_group;
    }
    else {
      $as_group ||= 'nogroup';
    }

    if($> != 0) {
          # Not root? Then we're ourselves
        ($as_user)  = getpwuid($>);
        ($as_group) = getgrgid(POSIX::getgid());
    }

    $background = 1 if(!defined $background);
    $background = find_option('-X') ? 0 : $background;

    $loglevel   = $background ? $INFO : $DEBUG
      if(!defined $loglevel);
    $loglevel   = find_option('-v') ? $DEBUG : $loglevel;

    for (qw(start stop restart status)) {
        if( find_option( $_ ) ) {
            $action = $_;
            last;
        }
    }
    
    if($action eq "stop" or $action eq "status") {
        $background = 0;
    }

    if( Log::Log4perl->initialized() ) {
        DEBUG "Log4perl already initialized, doing nothing";
    } elsif( $action eq "status" ) {
        Log::Log4perl->easy_init( $loglevel );
    } elsif( $l4p_conf ) {
        Log::Log4perl->init( $l4p_conf );
    } elsif( $logfile ) {
        my $levelstring = Log::Log4perl::Level::to_level( $loglevel );
        Log::Log4perl->init(\ qq{
            log4perl.logger = $levelstring, FileApp
            log4perl.appender.FileApp = Log::Log4perl::Appender::File
            log4perl.appender.FileApp.filename = $logfile
            log4perl.appender.FileApp.owner    = $as_user
              # this umask is only temporary
            log4perl.appender.FileApp.umask    = 0133
            log4perl.appender.FileApp.layout   = PatternLayout
            log4perl.appender.FileApp.layout.ConversionPattern = %d %m%n
        });
    }

    if(!$background) {
        DEBUG "Running in foreground";
    }
}

###########################################
sub daemonize {
###########################################
    cmd_line_parse();

      # Check beforehand so the user knows what's going on.
    if(! -w dirname($pidfile) or -f $pidfile and ! -w  $pidfile) {
        my ($name,$passwd,$uid) = getpwuid($>);
        LOGDIE "$pidfile not writable by user $name";
    }
    
    if($action eq "status") {
        exit status();
    }

    if($action eq "stop" or $action eq "restart") {
        my $exit_code = LSB_NOT_RUNNING;

        if(-f $pidfile) {
            my $pid = pid_file_read();
            if(kill 0, $pid) {
                kill $kill_sig, $pid;
                my $killed = 0;
                for (1..$kill_retries) {
                    if(!kill 0, $pid) {
                        INFO "Process $pid stopped successfully.";
                        unlink $pidfile or die "Can't remove $pidfile ($!)";
                        $exit_code = LSB_OK;
                        $killed++;
                        last;
                    }
                    INFO "Process $pid still running, waiting ...";
                    sleep 1;
                }
                if(! $killed) {
                    ERROR "Process $pid still up, out of retries, giving up.";
                    $exit_code = LSB_DEAD_PID_EXISTS;
                }
            } else {
                ERROR "Process $pid not running\n";
                unlink $pidfile or die "Can't remove $pidfile ($!)";
                $exit_code = LSB_NOT_RUNNING;
            }
        } else {
            ERROR "According to my pidfile, there's no instance ",
                  "of me running.";
            $exit_code = LSB_NOT_RUNNING;
        }

        if($action eq "restart") {
            sleep 1;
        } else {
            exit $exit_code;
        }
    }
      
    if ( my $num = pid_file_process_running() ) {
        LOGWARN "Already running: $num (pidfile=$pidfile)\n";
        exit ALREADY_RUNNING;
    }

    if( $background ) {
        detach( $as_user );
    } elsif ($as_user) {
        id_switch();
    }

    my $prev_sig   = $SIG{__DIE__};
    my $master_pid = $$;

    DEBUG "Defining die handler";

    $SIG{__DIE__} = sub { 
        DEBUG __PACKAGE__, " die handler triggered.";
          # In case we had a previously defined signal handler, call
          # it first and add ours to the end of the chain.
        $prev_sig->(@_) if ($prev_sig);

        if( $master_pid != $$ ) {
              # Verify that it's the main process calling the
              # handler and not a previously forked child.
            DEBUG "Die handler called for pid $$ but master pid is $master_pid";
        } elsif( !defined $^S or $^S != 0 ) {
              # Make sure it's not an eval{} triggering the handler.
            DEBUG "Die handler called by eval. Ignored.";
        } else {
            DEBUG "Die handler removes pidfile $pidfile";
            unlink $pidfile or warn "Cannot remove $pidfile";
        }
    };
    
    return 1;
}

###########################################
sub detach {
###########################################
    my($as_user) = @_;

      # [rt #75219]
    umask(0);
 
      # Make sure the child isn't killed when the user closes the
      # terminal session before the child detaches from the tty.
    $SIG{'HUP'} = 'IGNORE';
 
    my $child = fork();
 
    if(! defined $child ) {
        LOGDIE "Fork failed ($!)";
    }
 
    if( $child ) {
        # parent doesn't do anything
        exit 0;
    }
 
        # Become the session leader of a new session, become the
        # process group leader of a new process group.
    POSIX::setsid();
 
    if( defined $pidfile ) {
        INFO "Process ID is $$";
        pid_file_write($$);
        INFO "Written to $pidfile";
    }

    if($as_user) {
        id_switch();
    }
 
        # close std file descriptors
    if(-e "/dev/null") {
        # On Unix, we want to point these file descriptors at /dev/null,
        # so that any libary routines that try to read form stdin or
        # write to stdout/err will have no effect (Stevens, APitUE, p. 426
        # and [RT 51066].
        open STDIN, '/dev/null';
        open STDOUT, '>>/dev/null';
        open STDERR, '>>/dev/null';
    } else {
        close(STDIN);
        close(STDOUT);
        close(STDERR);
    }
}

###########################################
sub id_switch {
###########################################
    if($> == 0) {
        # If we're root, become user set as 'as_user' and the group in
        # 'as_group'.

        # Set the group first because it only works when still root
        my ($group,undef,$gid)  = getgrnam($as_group);

        if(! defined $group) {
            LOGDIE "Cannot switch to group $as_group";
        }
        POSIX::setgid($gid);

        my ($name,$passwd,$uid) = getpwnam($as_user);
        if(! defined $name) {
            LOGDIE "Cannot switch to user $as_user";
        }
        POSIX::setuid( $uid );
    }
}
    
###########################################
sub status {
###########################################

      # Define exit codes according to 
      # http://refspecs.freestandards.org/LSB_3.1.1/LSB-Core-generic/LSB-Core-generic/iniscrptact.html
    my $exit_code = LSB_UNKNOWN;

    print "Pid file:    $pidfile\n";
    if(-f $pidfile) {
        my $pid = pid_file_read();
        my $running = process_running($pid);
        print "Pid in file: $pid\n";
        print "Running:     ", $running ? "yes" : "no", "\n";
        if($running) {
              # see above
            $exit_code = LSB_OK;
        } else {
              # see above
            $exit_code = LSB_DEAD_PID_EXISTS;
        }
    } else {
        print "No pidfile found\n";
        $exit_code = LSB_NOT_RUNNING;
    }

    if( proc_processtable_available() ) {
        my @cmdlines = processes_running_by_name( $appname );
        print "Name match:  ", scalar @cmdlines, "\n";
        for(@cmdlines) {
            print "    ", $_, "\n";
        }
    }

    return $exit_code;
}


###########################################
sub process_running {
###########################################
    my($pid) = @_;

    my $rc = kill( 0, $pid );

    if( $rc ) {
          # pseudo signal got delivered, process exists
        return 1;
    } elsif( $! == ESRCH ) {
          # process doesn't exist
        return 0;
    } elsif( $! == EPERM ) {
          # process does exist, but we don't have permission to
          # send the signal
        return 1;
    }

      # Weirdness ensued.
    return 0;
}

###########################################
sub processes_running_by_name {
###########################################
    my($name) = @_;

    require Proc::ProcessTable;

    $name = basename($name);
    my @procs = ();

    my $t = Proc::ProcessTable->new();

    foreach my $p ( @{$t->table} ){
        if($p->cmndline() =~ /\b\Q${name}\E\b/) {
            next if $p->pid() == $$;
            DEBUG "Match: ", $p->cmndline();
            push @procs, $p->cmndline();
        }
    }
    return @procs;
}

###########################################
sub appname {
###########################################
    my $appname = basename($0);

      # Make sure -T regards it as untainted now
    ($appname) = ($appname =~ /([\w-]+)/);

    return $appname;
}

###########################################
sub find_option {
###########################################
    my($opt, $has_arg) = @_;

    my $idx = 0;

    for my $argv (@ARGV) {
        if($argv eq $opt) {
            if( $has_arg ) {
                my @args = splice @ARGV, $idx, 2;
                return $args[1];
            } else {
                return splice @ARGV, $idx, 1;
            }
        }

        $idx++;
    }

    return undef;
}

###########################################
sub def_or {
###########################################
    if(! defined $_[0]) {
        $_[0] = $_[1];
    }
}

###########################################
sub pid_file_write {
###########################################
    my($pid) = @_;

    sysopen FILE, $pidfile, O_RDWR|O_CREAT, 0644 or
        LOGDIE "Cannot open pidfile $pidfile";
    flock FILE, LOCK_EX;
    seek(FILE, 0, 0);
    print FILE "$pid\n";
    close FILE;
}

###########################################
sub pid_file_read {
###########################################
    open FILE, "<$pidfile" or LOGDIE "Cannot open pidfile $pidfile";
    flock FILE, LOCK_SH;
    my $pid = <FILE>;
    chomp $pid if defined $pid;
    close FILE;
    $pid =~ /^(\d+)$/; # Untaint
    return $1;
}

###########################################
sub pid_file_process_running {
###########################################
    if(! -f $pidfile) {
        return undef;
    }
    my $pid = pid_file_read();
    if(! $pid) {
        return undef;
    }
    if(process_running($pid)) {
        return $pid;
    }

    return undef;
}

###########################################
sub proc_processtable_available {
###########################################
    my $module = "Proc::ProcessTable";

    eval "require $module;";

    if( $@ ) {
        return 0;
    }

    return 1;
}

1;

__END__

=head1 NAME

App::Daemon - Start an Application as a Daemon

=head1 SYNOPSIS

     # Program:
   use App::Daemon qw( daemonize );
   daemonize();
   do_something_useful(); # your application

     # Then, in the shell: start application,
     # which returns immediately, but continues 
     # to run do_something_useful() in the background
   $ app start
   $

     # stop application
   $ app stop

     # start app in foreground (for testing)
   $ app -X

     # show if app is currently running
   $ app status

=head1 DESCRIPTION

C<App::Daemon> helps running an application as a daemon. The idea is
that you prepend your script with the 

    use App::Daemon qw( daemonize ); 
    daemonize();

and 'daemonize' it that way. That means, that if you write

    use App::Daemon qw( daemonize ); 

    daemonize();
    sleep(10);

you'll get a script that, when called from the command line, returns 
immediatly, but continues to run as a daemon for 10 seconds.

Along with the
common features offered by similar modules on CPAN, it

=over 4

=item *

supports logging with Log4perl: In background mode, it logs to a 
logfile. In foreground mode, log messages go directly to the screen.

=item *

detects if another instance is already running and ends itself 
automatically in this case.

=item *

shows with the 'status' command if an instance is already running
and which PID it has:

    ./my-app status
    Pid file:    ./tt.pid
    Pid in file: 14914
    Running:     no
    Name match:  0

=back

=head2 Actions

C<App::Daemon> recognizes three different actions:

=over 4

=item my-app start

will start up the daemon. "start" itself is optional, as this is the 
default action, 
        
        $ ./my-app
        $
        
will also run the 'start' action. By default, it will create a pid file
and a log file in the current directory
(named C<my-app.pid> and C<my-app.log>. To change these locations, see
the C<-l> and C<-p> options.

If the -X option is given, the program
is running in foreground mode for testing purposes:

        $ ./my-app -X
        ...

=item stop

will find the daemon's PID in the pidfile and send it a SIGTERM signal. It
will verify $App::Daemon::kill_retries times if the process is still alive,
with 1-second sleeps in between.

To have App::Daemon send a different signal than SIGTERM (e.g., SIGINT), set

    use POSIX;
    $App::Daemon::kill_sig = SIGINT;

Note that his requires the numerial value (SIGINT via POSIX.pm), not a
string like "SIGINT".

=item status

will print out diagnostics on what the status of the daemon is. Typically,
the output looks like this:

    Pid file:    ./tt.pid
    Pid in file: 15562
    Running:     yes
    Name match:  1
        /usr/local/bin/perl -w test.pl

This indicates that the pidfile says that the daemon has PID 15562 and
that a process with this PID is actually running at this moment. Also,
a name grep on the process name in the process table results in 1 match,
according to the output above.

Note that the name match is unreliable, as it just looks for a command line
that looks approximately like the script itself. So if the script is
C<test.pl>, it will match lines like "perl -w test.pl" or 
"perl test.pl start", but unfortunately also lines like 
"vi test.pl".

If the process is no longer running, the status output might look like
this instead:

    Pid file:    ./tt.pid
    Pid in file: 14914
    Running:     no
    Name match:  0

The status commands exit code complies with 

    http://refspecs.freestandards.org/LSB_3.1.1/LSB-Core-generic/LSB-Core-generic/iniscrptact.html

and returns

    0: if the process is up and running
    1: the process is dead but the pid file still exists
    3: the process is not running

These constants are defined within App::Daemon to help writing test
scripts:

    use constant LSB_OK               => 0;
    use constant LSB_DEAD_PID_EXISTS  => 1;
    use constant LSB_DEAD_LOCK_EXISTS => 2;
    use constant LSB_NOT_RUNNING      => 3;
    use constant LSB_UNKNOWN          => 4;
    use constant ALREADY_RUNNING      => 150;

=back

=head2 Command Line Options

=over 4

=item -X

Foreground mode. Log messages go to the screen.

=item -l logfile

Logfile to send Log4perl messages to in background mode. Defaults
to C<./[appname].log>. Note that having a logfile in the current directory
doesn't make sense except for testing environments, make sure to set this
to somewhere within C</var/log> for production use.

=item -u as_user

User to run as if started as root. Defaults to 'nobody'.

=item -g as_group

Group to run as if started as root.  Defaults to 'nogroup'.

=item -l4p l4p.conf

Path to Log4perl configuration file. Note that in this case the -v option 
will be ignored.

=item -p pidfile

Where to save the pid of the started process.
Defaults to C<./[appname].pid>.
Note that 
having a pidfile in the current directory
doesn't make sense except for testing environments, make sure to set this
to somewhere within C</var/run> for production use.

=item -v

Increase default Log4perl verbosity from $INFO to $DEBUG. Note that this
option will be ignored if Log4perl is initialized independently or if
a user-provided Log4perl configuration file is used.

=back

=head2 Setting Parameters

Instead of setting paramteters like the logfile, the pidfile etc. from
the command line, you can directly manipulate App::Daemon's global
variables:

    use App::Daemon qw(daemonize);

    $App::Daemon::logfile    = "mylog.log";
    $App::Daemon::pidfile    = "mypid.log";
    $App::Daemon::l4p_conf   = "myconf.l4p";
    $App::Daemon::background = 1;
    $App::Daemon::as_user    = "nobody";
    $App::Daemon::as_group   = "nogroup";

    use Log::Log4perl qw(:levels);
    $App::Daemon::loglevel   = $DEBUG;

    daemonize();

=head2 Application-specific command line options

If an application needs additional command line options, it can 
use whatever is not yet taken by App::Daemon, as described previously
in the L<Command Line Options> section.

However, it needs to make sure to remove these additional options before
calling daemonize(), or App::Daemon will complain. To do this, create 
an options hash C<%opts> and store application-specific options in there
while removing them from @ARGV:

    my %opts = ();

    for my $opt (qw(-k -P -U)) {
        my $v = App::Daemon::find_option( $opt, 1 );
        $opts{ $opt } = $v if defined $v;
    }

After this, options C<-k>, C<-P>, and C<-U> will have disappeared from
@ARGV and can be checked in C<$opts{k}>, C<$opts{P}>, and C<$opts{U}>.

=head2 Gotchas

=over 4

=item Log File Permissions

If the process is started as root but later drops permissions to a
non-priviledged user for security purposes, it's important that 
logfiles are created with correct permissions.

If they're created as root when the program starts, the non-priviledged
user won't be able to write to them later (unless they're world-writable
which is also undesirable because of security concerns).

The best strategy to handle this case is to specify the non-priviledged
user as the owner of the logfile in the Log4perl configuration:

    log4perl.logger = DEBUG, FileApp
    log4perl.appender.FileApp = Log::Log4perl::Appender::File
    log4perl.appender.FileApp.filename = /var/log/foo-app.log
    log4perl.appender.FileApp.owner    = nobody
    log4perl.appender.FileApp.layout   = PatternLayout
    log4perl.appender.FileApp.layout.ConversionPattern = %d %m%n

This way, the process starts up as root, creates the logfile if it 
doesn't exist yet, and changes its owner to 'nobody'. Later, when the
process assumes the identity of the user 'nobody', it will continue
to write to the logfile without permission problems.

=item Log4perl Categories

Note that App::Daemon is logging messages in Log4perl's App::Daemon 
namespace. So, if you're running your own Log4perl configuration and
define a root logger like

    log4perl.logger=DEBUG, appendername

then App::Daemon's messages will bubble up to it and be visible in
the output. If you don't want that, either use

    log4perl.logger.My.App=DEBUG, appendername

to explicitly enable verbose logging in your application namespace
(and not in App::Daemon's) or tone down App::Daemon's verbosity via

    log4perl.logger.App.Daemon=ERROR

explicitly. If you want more details on basic Log4perl features,
check out the L<Log::Log4perl> manual page.

=back

=head2 Detach only

If you want to create a daemon without the fancy command line parsing
and PID file checking functions, use

    use App::Daemon qw(detach);
    detach();
    # ... some code here

This will fork a child, terminate the parent and detach the child from
the terminal. Issued from the command line, the program above will
continue to run the code following the detach() call but return to the
shell prompt immediately.

=head1 AUTHOR

    2008, Mike Schilli <cpan@perlmeister.com>
    
=head1 LICENSE

Copyright 2008-2012 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

