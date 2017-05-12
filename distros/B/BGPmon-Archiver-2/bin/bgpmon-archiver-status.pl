#!/usr/bin/perl
our $VERSION = '2.0';
# *
# *
# *      Copyright (c) 2012 Colorado State University
# *
# *      Permission is hereby granted, free of charge, to any person
# *      obtaining a copy of this software and associated documentation
# *      files (the "Software"), to deal in the Software without
# *      restriction, including without limitation the rights to use,
# *      copy, modify, merge, publish, distribute, sublicense, and/or
# *      sell copies of the Software, and to permit persons to whom
# *      the Software is furnished to do so, subject to the following
# *      conditions:
# *
# *      The above copyright notice and this permission notice shall be
# *      included in all copies or substantial portions of the Software.
# *
# *      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# *      EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# *      OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# *      NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# *      HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# *      WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# *      FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# *      OTHER DEALINGS IN THE SOFTWARE.\
# *
# *
# *  File: bgpmon-archiver-status.pl
# *  Authors: Kaustubh Gadkari, Dan Massey, Cathie Olschanowsky
# *  Date: Septemer 27, 2012
# *

use strict;
use warnings;
use Getopt::Long;
use BGPmon::Log;
use Net::SMTP;

my $prog_name = $0;

$! = 1;

# Variables for logging
my $syslog = 0;
my $loglevel = 7;
my $logfile;

# install locations
# location of bgpmon-archiver etc directory
my $var_dir;
if (defined($ENV{'ARCHIVER_STATE'})) {
    $var_dir = $ENV{'ARCHIVER_STATE'};
} else {
    $var_dir = '/var/run/bgpmon-archiver';
}

# Mail server
my $mailhost = 'alpha.netsec.colostate.edu';

# Parse command line options.
my $result = GetOptions("syslog" => \$syslog,
    "loglevel=i" => \$loglevel,
    "logfile=s" => \$logfile,
    "mailhost=s" => \$mailhost,
);

my $ret = BGPmon::Log::log_init(log_level => $loglevel,
    logfile => $logfile,
    use_syslog => $syslog,
    prog_name => $prog_name);

# check the archiver is running and restart if not.
my $pid = check_pid();
if ($pid == -1) {
    report_error("Fatal archiver error. Unable to get PID or restart.");
    exit 1;
}

report_success();

exit 0;

# get the PID for the archiver or -1 if no PID found
sub check_pid {
    # Check if pid file exists
    my $pid_file = "$var_dir/archiver.pid";

    until (-e $pid_file) {
        restart_archiver();
    }

    my $pid = get_pid();

    # Loop through output of ps command.
    my $ret = 0;
    if (!open(PS_F, "ps aux|")) {
        return -1;
    }
    while (<PS_F>) {
        $_ =~ s/\s+/ /g;
        my @ps_elems = split;
        my $ps_pid = $ps_elems[1];
        # Skip first line of output of ps aux.
        if ($ps_pid eq "PID") {
            next;
        }
        if ($ps_pid == $pid) {
            $ret = $pid;
        }
    }
    close(PS_F);

    if ($ret == $pid) {
        return $ret;
    } else {
        $pid = restart_archiver();
        return $pid;
    }
}

sub get_pid {
    my $pid_file = "$var_dir/archiver.pid";
    unless (-e $pid_file) {
        return -1;
    }

    if (!open(PID_F, $pid_file)) {
        report_error("Unable to read existing PID file $pid_file.");
        return -1;
    }
    my $pid = <PID_F>;
    close(PID_F);
    return $pid;
}

# restart the archiver
sub restart_archiver {
    # Check if the init script exists. If not, report error and quit.
    unless (-e '/etc/init.d/bgpmon-archiver' and -x '/etc/init.d/bgpmon-archiver') {
        report_error("Could not find init script /etc/init.d/bgpmon-archiver. Restart failed.");
        exit 1;
    }

    report_warning("Attempting to restart bgpmon-archiver");

    # if this fails, how long do I wait to try again
    my $try_again_time = 2;
    # if this fails, increase delay time by multiply by delay factor
    my $delay_factor = 2;

    # once we restart the archiver, how long do we expect it to take until it starts.
    my $timeout = 180;   # if the archiver isn't getting updates within 3 minutes, it didn't start
    my $time = 0;    # how much time has elapsed since the archiver was relaunched
    my $check_delay = 3;   # check every 3 seconds to see how the archiver is doing
    my $elapsed_time = 0;  # how much time has elapsed since we launched the startup script?

    my @args = qw(/etc/init.d/bgpmon-archiver start);
    # continue trying until we get the archiver started
    while (1) {
        system(@args);
        if ($?) {
        # if the startup script failed, no need to wait and see if successfully started.   just set time out and that will drop us to end of loop.
            $time = $timeout;
        } else {
            # we launched the startup script,  now we need to run through all the checks before the timeout...
            $time = 0;
            my $new_pid = get_pid();
            while ($time < $timeout && $new_pid == -1) {
                # didn't see a valid PID yet so sleep and check again
                sleep($check_delay);
                $elapsed_time += $check_delay;
                $time = $elapsed_time;
            }
            # if we didn't time out,  it successfully restarted so log that fact and quit
            if ($time < $timeout) {
                report_success("Successfully restarted bgpmon_archiver");
                exit 0;
            # otherwise it didn't successfully restart,  adjust the delay until trying again and start over
            } else {
                $try_again_time = $try_again_time * $delay_factor;
                report_warning("Failed to restart bgpmon_archiver, will try again in $try_again_time seconds");
                sleep($try_again_time);
            }
            # if we reach here,   the program has timed out and the delayed for some time.   go back to start and try another restart
        }
    }
    # this is never reached....   the loop either continues to retry forever or the program exits if the restart succeeded
    return 0;
}

# report an error
sub report_error {
    my $msg = shift;
    my $subject = "bgpmon-archiver error";
    BGPmon::Log::log_err($msg);
    my $ret = send_mail($msg, $subject);
    if ($ret == 0) {
        return 0;
    } else {
        BGPmon::Log::log_err("Error sending email.");
        return -1;
    }
}

# report a warning
sub report_warning {
    my $msg = shift;
    my $subject = "bgpmon-archiver warning";
    BGPmon::Log::log_warn($msg);
    my $ret = send_mail($msg, $subject);
    if ($ret == 0) {
        return 0;
    } else {
        BGPmon::Log::log_err("Error sending email.");
        return -1;
    }
}

# report success
sub report_success {
    my $msg = shift;
    my $subject = "bgpmon-archiver success";
    BGPmon::Log::log_info($msg);
    my $ret = send_mail($msg, $subject);
    if ($ret == 0) {
        return 0;
    } else {
        BGPmon::Log::log_err("Error sending email.");
        return -1;
    }
    send_mail($msg, $subject);
    return 0;
}

# Send email
sub send_mail {
    my ($msg, $subject) = @_;
    my $smtp = Net::SMTP->new($mailhost);
    $smtp->mail($ENV{USER});
    $smtp->to('kaustubh@cs.colostate.edu');

    $smtp->data();
    $smtp->datasend("To: kaustubh\@cs.colostate.edu\n");
    $smtp->datasend("\n");
    $smtp->datasend($msg);
    $smtp->dataend();
    $smtp->quit();

    return 0;
}
