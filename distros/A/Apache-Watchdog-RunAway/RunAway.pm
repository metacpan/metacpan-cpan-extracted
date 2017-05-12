package Apache::Watchdog::RunAway;

$Apache::VMonitor::VERSION = '1.00';

use strict;

BEGIN {
    use constant MP2 => eval { require mod_perl; $mod_perl::VERSION > 1.99 };
    die "mod_perl is required to run this module: $@" if $@;

    if (MP2) {
        require APR::Pool;
    } else {
        # nada
    }
}

use Apache::Scoreboard ();
use Symbol ();

if (MP2 && require Apache::MPM && Apache::MPM->is_threaded()) {
    die __PACKAGE__ . " is suitable to be used only under prefork MPM";
}

use subs qw(debug log_error);

########## user configurable variables #########

# timeout before counted as hang (in seconds)
# 0 means deactivated
$Apache::Watchdog::RunAway::TIMEOUT = 0;

# polling intervals in seconds
$Apache::Watchdog::RunAway::POLLTIME = 60;

# debug mode
$Apache::Watchdog::RunAway::DEBUG = 0;

# lock file
$Apache::Watchdog::RunAway::LOCK_FILE = "/tmp/safehang.lock";

# log file
$Apache::Watchdog::RunAway::LOG_FILE = "/tmp/safehang.log";

# scoreboard URL
$Apache::Watchdog::RunAway::SCOREBOARD_URL = "http://localhost/scoreboard";

# give details about the request that was hanging
$Apache::Watchdog::RunAway::VERBOSE = 0;

########## internal variables #########

# request processing times cache
my %req_proc_time = ();

# current request number
my %req_number = ();

my $log_fh;

# check whether the monitor is already running
# returns the PID if lockfile exists
##############
sub is_running {

    return 0 unless -e $Apache::Watchdog::RunAway::LOCK_FILE;

    my $pid = get_proc_pid();

    warn <<EOT if $Apache::Watchdog::RunAway::DEBUG;
$0 is already running (proc $pid).
Locked in $Apache::Watchdog::RunAway::LOCK_FILE.
EOT

    return $pid;

}


# returns the PID if lockfile exists or 0
################
sub get_proc_pid {

    my $fh = Symbol::gensym();
    open $fh, $Apache::Watchdog::RunAway::LOCK_FILE
        or die "Cannot open $Apache::Watchdog::RunAway::LOCK_FILE: $!";
    chomp (my $pid = <$fh>);
    # untaint
    $pid = $pid =~ /^(\d+)$/ ? $1 : 0;
    close $fh;

    return $pid;
}


# create the lockfile and put the PID inside
##############
sub lock {

    my $fh = Symbol::gensym();
    open $fh, ">".$Apache::Watchdog::RunAway::LOCK_FILE
        or die "Cannot open $Apache::Watchdog::RunAway::LOCK_FILE: $!";
    flock $fh, 2;
    seek $fh, 0, 0;
    print $fh $$;
    close $fh;

}


#################
sub stop_monitor {

    unless (-e $Apache::Watchdog::RunAway::LOCK_FILE) {
        warn <<EOT if $Apache::Watchdog::RunAway::DEBUG;
$0: Lockfile $Apache::Watchdog::RunAway::LOCK_FILE does not exist. Exiting...
EOT
        return;
    }

    my $pid = get_proc_pid();

    my $killed = kill 15, $pid if $pid;
    warn "$0: monitor process $pid was killed\n" 
        if $killed && $Apache::Watchdog::RunAway::DEBUG;

    # unlock the lockfile
    unlink $Apache::Watchdog::RunAway::LOCK_FILE;

}


##################
sub start_detached_monitor {

    defined (my $watchdog_pid = fork) or die "Cannot fork: $!\n";

    if ($watchdog_pid) {
        warn "detached monitor pid $watchdog_pid started\n"
            if $Apache::Watchdog::RunAway::DEBUG;
        return $watchdog_pid;
    }
    else {
        start_monitor();
        CORE::exit();
    }
}


#################
sub start_monitor {

    # 0 means don't monitor
    return unless $Apache::Watchdog::RunAway::TIMEOUT;

    # handle the case where apache restarts itself, either on start or
    # with PerlFresh ON... this is a closure to protect this variable
    # from user. it's inaccessable outside of this module
    return if is_running();

    # The forked process is supposed to run as long as main process
    # runs, so we don't care about wait()
    warn "$0: spawned a monitor process $$\n"
        if $Apache::Watchdog::RunAway::DEBUG;

    # create a lock file
    lock();

    # neverending loop
    while (1) {
        monitor();
        debug "sleeping $Apache::Watchdog::RunAway::POLLTIME";
        sleep $Apache::Watchdog::RunAway::POLLTIME;
    }

}

my $pool;

# the real code that does all the accounting and killings
############
sub monitor {

    die "\$Apache::Watchdog::RunAway::SCOREBOARD_URL is not set"
        unless $Apache::Watchdog::RunAway::SCOREBOARD_URL;

    my @args = ($Apache::Watchdog::RunAway::SCOREBOARD_URL);
    if (MP2) {
        # mp's Apache::Scoreboard::fetch needs a pool arg
        $pool = APR::Pool->new;
        unshift @args, $pool;
    }

    my $image = Apache::Scoreboard->fetch(@args);
    unless ($image){
        # reset the counters and timers
        %req_proc_time = ();
        %req_number = ();
        debug "couldn't retrieve the scoreboard image ",
              "from $Apache::Watchdog::RunAway::SCOREBOARD_URL";
        return;
    }

    for (my $i = 0; $i < $image->server_limit; $i++) {
        my $parent_score = MP2 ? $image->parent_score($i) : $image->servers($i);
        next unless $parent_score;

        my $pid          = MP2 ? $parent_score->pid : $image->parent($i)->pid;

        last unless $pid;

        my $worker_score = MP2 ? $parent_score->worker_score : $parent_score;

        # we care only about processes that in 'W' status
        # processing. (W means 'writing to a client')
        next unless $worker_score->status eq 'W';

        # init if it's uninitialized (to non existant -1 count)
        # can't use ||= construct as a value can be 0...
        $req_number{$pid} = -1
            unless exists $req_number{$pid};

        # make sure the proc time is initialized
        $req_proc_time{$pid} ||= 0;

        my $count = $worker_score->my_access_count;
        debug "OK: $i $pid ",
            $worker_score->status, " $count ",
            $req_proc_time{$pid}, " ",
            $req_number{$pid};

        if ($count == $req_number{$pid}) {

            # the same request is still being processed
            if ($req_proc_time{$pid} > $Apache::Watchdog::RunAway::TIMEOUT) {

                my $error = <<EOT;
Killing httpd process $pid which is running for $req_proc_time{$pid} secs,
which is longer than $Apache::Watchdog::RunAway::TIMEOUT secs limit.
EOT
                if ($Apache::Watchdog::RunAway::VERBOSE) {
                    $error .= 'It was handling [' . $worker_score->request() .
                        '] for [' . $worker_score->client() . "]\n";
                }
                log_error $error;

                # META: should I kill or just send a SIGPIPE to a hanging process?
                kill 9, $pid;

            } else {
                #warn "o0o\n";
                # Note: this is not true processing time, since there is a
                # work done between sleeps, but it takes less than 1 second
                $req_proc_time{$pid} += $Apache::Watchdog::RunAway::POLLTIME;
            }

        } else {
            $req_number{$pid} = $count;	
            # reset time delta
            $req_proc_time{$pid} = 0;
        }

    }

}

sub debug {
    log_error(@_) if $Apache::Watchdog::RunAway::DEBUG > 1;
}

sub log_error {
    unless ($log_fh) {
        $log_fh = Symbol::gensym();
        open $log_fh, ">>$Apache::Watchdog::RunAway::LOG_FILE"
            or die "Cannot open $Apache::Watchdog::RunAway::LOG_FILE: $!";
        my $oldfh = select($log_fh); $| = 1; select($oldfh);
    }

    print $log_fh "[".scalar localtime()."] $$: " . __PACKAGE__ ,": ", @_, "\n";
}


=pod

=head1 NAME

Apache::Watchdog::RunAway - a Monitor for Terminating Hanging Apache Processes

=head1 SYNOPSIS

  use Apache::Watchdog::RunAway ();
  $Apache::Watchdog::RunAway::TIMEOUT = 0;
  $Apache::Watchdog::RunAway::POLLTIME = 60;
  $Apache::Watchdog::RunAway::DEBUG = 0;
  $Apache::Watchdog::RunAway::LOCK_FILE = "/tmp/safehang.lock";
  $Apache::Watchdog::RunAway::LOG_FILE = "/tmp/safehang.log";
  $Apache::Watchdog::RunAway::SCOREBOARD_URL = "http://localhost/scoreboard";
  $Apache::Watchdog::RunAway::VERBOSE = 0;

  Apache::Watchdog::RunAway::stop_monitor();
  Apache::Watchdog::RunAway::start_monitor();
  Apache::Watchdog::RunAway::start_detached_monitor();

=head1 DESCRIPTION

A module that monitors hanging Apache/mod_perl processes. You define
the time in seconds after which the process to be counted as
hanging. You also control the polling time between check to check.

When the process is considered as 'hanging' it will be killed and the
event logged into a log file. The log file is being opened on append,
so you can basically defined the same log file that uses Apache. 

You can start this process from startup.pl or through any other
method. (e.g. a crontab). Once started it runs indefinitely, untill
killed.

You cannot start a new monitoring process before you kill the old one.
The lockfile will prevent you from doing that.

Generally you should use the C<amprapmon> program that bundled with this
module's distribution package, but you can write your own code using
the module as well. See the amprapmon manpage for more info about it.

Methods:

=over

=item * stop_monitor()

Stops the process based on the PID in the lock file. Removes the lock
file.

=item * start_monitor()

Starts the monitor in the current process. Creates the lock file.

=item * start_detached_monitor()

Starts the monitor in a forked process. (used by
C<amprapmon>). Creates the lock file.

=back

=head1 WARNING

This is an alpha version of the module, so use it after a testing on
development machine. 

The most critical parameter is the value of
I<$Apache::Watchdog::RunAway::TIMEOUT> (see
L<CONFIGURATION|/CONFIGURATION>), since the processes will be killed
without waiting for them to quit (since they hung).

=head1 CONFIGURATION

Install and configure C<Apache::Scoreboard> module

  # mod_status should be compiled in (it is by default)
  ExtendedStatus On

  <Location /scoreboard>
    SetHandler perl-script
    PerlHandler Apache::Scoreboard::send
  </Location>

You also need to have mod_status built in and its extended status to
be turned on:

  ExtendedStatus On

Configure the Apache::Watchdog::RunAway parameters:

  $Apache::Watchdog::RunAway::TIMEOUT = 0;

The time in seconds after which the process is considered hanging. 0
means deactivated. The default is 0 (deactivated).

  $Apache::Watchdog::RunAway::POLLTIME = 60;

Polling intervals in seconds. The default is 60.

  $Apache::Watchdog::RunAway::DEBUG = 0;

Debug mode (0, 1 or 2). The default is 0.
Level 2 logs a lot of debug noise. Level 1 only logs killed processes info.

  $Apache::Watchdog::RunAway::LOCK_FILE = "/tmp/safehang.lock";

The process lock file location. The default is I</tmp/safehang.lock>

  $Apache::Watchdog::RunAway::LOG_FILE = "/tmp/safehang.log";

The log file location. Since it flocks the file, you can safely use
the same log file that Apache uses, so you will get the messages about
killed processes in file you've got used to. The default is
I</tmp/safehang.log>

  $Apache::Watchdog::RunAway::SCOREBOARD_URL = "http://localhost/scoreboard";

Since the process relies on scoreboard URL configured on any of your
machines (the URL returns a binary image that includes the status of
the server and its children), you must specify it. This enables you to
run the monitor on one machine while the server can run on the other
machine. The default is URI is I<http://localhost/scoreboard>.

  $Apache::Watchdog::RunAway::VERBOSE = 0;

When about to forcibly kill a child, it will report in the log the
first 64 bytes of the request and the remote IP of the client.

Start the monitoring process either with:

  start_detached_monitor()

that starts the monitor in a forked process or

  start_monitor()

that starts the monitor in the current process.

Stop the process with:

stop_monitor()

The distribution arrives with C<amprapmon> program that provides an rc.d
like or apachectl interface.

Instead of using a Perl interface you can start it from the command line:

  amprapmon start

or from the I<startup.pl> file:

  system "amprapmon start";

or

  system "amprapmon stop";
  system "amprapmon start";

or

  system "amprapmon restart";

As mentioned before, once started it sholdn't be killed. So you may
leave only the C<system "amprapmon start";> in the I<startup.pl>

You can start the C<amprapmon> program from crontab as well.

=head1 TUNING

The most important part of configuration is choosing the right timeout
(i.e. C<$Apache::Watchdog::RunAway::TIMEOUT>) parameter. You should
try this code that hangs and see the process killed after a timeout if
the monitor is running.

  my $r = shift;
  $r->send_http_header('text/plain');
  print "PID = $$\n";
  $r->rflush;
  while(1){
    $r->print("\0");
    $r->rflush;
    $i++;
    sleep 1;
  }

=head1 TROUBLESHOOTING

The module relies on correctly configured C</scoreboard> location
URI. If it cannot fetch the URI, it queitly assumes that server is
stopped. So either check manually that the C</scoreboard> location URI
is working or use the above test script that hangs to make sure it
works.

Enable debug mode for more information.

=head1 PREREQUISITES

You need to have B<Apache::Scoreboard> installed and configured in
I<httpd.conf>, which in turn requires mod_status to be installed. You
also have to enable the extended status, for this module to work
properly. In I<httpd.conf> add:

  ExtendedStatus On


=head1 BUGS

Was ist dieses?

=head1 SEE ALSO

L<Apache>, L<mod_perl>, L<Apache::Scoreboard>

=head1 AUTHORS

Stas Bekman <stas@stason.org>

=head1 COPYRIGHT

C<Apache::Watchdog::RunAway> is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
