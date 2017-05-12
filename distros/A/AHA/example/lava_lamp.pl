#!/usr/bin/perl 

=head1 NAME

   lava_lamp.pl --mode [watch|list|notify] --type [problem|recovery] \
                --name [AIN|switch name] --label <label> --debug \
                --config <path-to-perl-config>

=head1 DESCRIPTION

Simple example how to use L<"AHA"> for controlling AVM AHA switches. I.e. 
it is used for using a Lava Lamp as a Nagios Notification handler.

It also tries to check that:

=over

=item * 

The lamp can be switched on only during certain time periods

=item *

The lamp doesn't run longer than a maximum time (e.g. 6 hours) 
(C<$LAMP_MAX_TIME>)

=item *

That the lamp is not switched on again after being switched off within a
certain time period (C<$LAMP_REST_TIME>)

=item *

That manual switches are detected and recorded

=back

This script knows three modes:

=over

=item watch

The "watch" mode is used for ensuring that the lamp is not switched on for
certain time i.e. during the night. The Variable C<$LAMP_ON_TIME_TABLE> can be
used to customize the time ranges on a weekday basis. 

=item notify

The "notify" mode is used by a notification handler, e.g. from Nagios or from
Jenkins. In this mode, the C<type> parameter is used for signaling whether the
lamp should be switched on ("problem") or off ("recovery").

=item list

This scripts logs all activities in a log file C<$LOG_FILE>. With the "list"
mode, all history entries can be viewed. 

=back

=cut

# ===========================================================================
# Configuration section

# Configuration required for accessing the switch. 
my $SWITCH_CONFIG = 
    {
     # AVM AHA Host for controlling the devices 
     host => "fritz.box",
     
     # AVM AHA Password for connecting to the $AHA_HOST     
     password => "s!cr!t",
     
     # AVM AHA user role (undef if no roles are in use)
     user => undef,
     
     # Name of AVM AHA switch
     id => "Lava Lamp"
    };

# Time how long the lamp should be at least be kept switched off (seconds)
my $LAMP_REST_TIME = 60 * 60;

# Maximum time a lamp can be on 
my $LAMP_MAX_TIME = 5 * 60 * 60; # 5 hours

# When the lamp can be switched on. The values can contain multiple time
# windows defined as arrays
my $LAMP_ON_TIME_TABLE = 
    {
     "Sun" => [ ["7:55",  "23:00"] ],
     "Mon" => [ ["6:55",  "23:00"] ],
     "Tue" => [ ["13:55", "23:00"] ],
     "Wed" => [ ["13:55", "23:00"] ],
     "Thu" => [ ["13:55", "23:00"] ],
     "Fri" => [ ["6:55",  "23:00"] ],
     "Sat" => [ ["7:55",  "23:00"] ],     
    };

# File holding the lamp's status
my $STATUS_FILE = "/var/run/lamp.status";

# Log file where to log to 
my $LOG_FILE = "/var/log/lamp.log";

# Stop file, when, if exists, keeps the lamp off
my $OFF_FILE = "/tmp/lamp_off";

# Time back in passed assumed when switching was done manually (seconds)
# I.e. if a manual state change is detected, it is assumed that it was back 
# that amount of seconds in the past (5 minutes here)
my $MANUAL_DELTA = 5 * 60;

# Maximum number of history entries to store
my $MAX_HISTORY_ENTRIES = 1000;

# ============================================================================
# End of configuration

use Storable qw(fd_retrieve store_fd store retrieve);
use Data::Dumper;
use feature qw(say);
use Fcntl qw(:flock);
use Getopt::Long;
use strict;

my %opts = ();
GetOptions(\%opts, 'type=s','mode=s','debug!','name=s','label=s','config=s');

my $DEBUG = $opts{debug};
read_config_file($opts{config}) if $opts{config};
init_status();

my $mode = $opts{'mode'} || "list";

# List mode doesnt need a connection
list() and exit if $mode eq "list";

# Open status and lock
my $status = fetch_status();

# Name and connection parameters
my $lamp = open_lamp($SWITCH_CONFIG,$opts{name});

# Check current switch state    
my $is_on = $lamp->is_on();

# Log a manual switch which might has happened in between checks or notification
log_manual_switch($status,$is_on);

if ($mode eq "watch") {
   # Watchdog mode If the lamp is on but out of the period, switch it
    # off. Also, if it is running alredy for too long. $off_file can be used 
    # to switch it always off.
    my $in_period = check_on_period();
    if ($is_on && (-e $OFF_FILE || 
                   !$in_period || 
                   lamp_on_for_too_long($status))) {
        # Switch off lamp whether the stop file is switched on when we are off the
        # time window    
        $lamp->off();
        update_status($status,0,$mode);
    } elsif (!$is_on && $in_period && has_trigger($status)) {
        $lamp->on();
        update_status($status,1,"notif",undef,trigger_label($status));
        delete_trigger($status);
    }
} elsif ($mode eq "notif") {
    my $type = $opts{type} || die "No notification type given";
    if (lc($type) =~ /^(problem|custom)$/ && !$is_on) {
        if (check_on_period()) {
            # If it is a problem and the lamp is not on, switch it on, 
            # but only if the lamp is not 'hot' (i.e. was not switch off only 
            # $LAMP_REST_TIME
            my $last_hist = get_last_entry($status);
            my $rest_time = time - $LAMP_REST_TIME;
            if (!$last_hist || $last_hist->[0] < $rest_time) {
                $lamp->on();
                update_status($status,1,$mode,time,$opts{label});
            } else {
                info("Lamp not switched on because the lamp was switched off just before ",
                     time - $last_hist->[0]," seconds");
            }
        } else {
            # Notification received offtime, remember to switch on the lamp
            # when in time
            info("Notification received in an off-period: type = ",$type," | ",$opts{label});
            set_trigger($status,$opts{label});
        }
    } elsif (lc($type) eq 'recovery') {
        if ($is_on) {
            # If it is a recovery switch it off
            $lamp->off();
            update_status($status,0,$mode,time,$opts{label});
        } else {
            # It's already off, but remove any trigger marker
            delete_trigger($status);
        }
    } else {
        info("Notification: No state change. Type = ",$type,", State = ",$is_on ? "On" : "Off",
            " | Check Period: ",check_on_period());
    }
} else {
    die "Unknow mode '",$mode,"'";
}

if ($DEBUG) {
    info(Dumper($status));
}

# Logout, we are done
close_lamp($lamp);

store_status($status);

# ================================================================================================

sub info {
    if (open (F,">>$LOG_FILE")) {
        print F scalar(localtime),": ",join("",@_),"\n";
        close F;
    }
}

# List the status file
sub list {
    my $status = retrieve $STATUS_FILE;
    my $hist_entries = $status->{hist};
    for my $hist (@{$hist_entries}) {
        print scalar(localtime($hist->[0])),": ",$hist->[1] ? "On " : "Off"," -- ",$hist->[2]," : ",$hist->[3],"\n";
    }
    print "Content: ",Dumper($status) if $DEBUG;
    return 1;
} 

# Create empty status file if necessary
sub init_status {
    my $status = {};
    $status->{hist} = [];
    if (! -e $STATUS_FILE) {
        store $status,$STATUS_FILE;
    }
}

sub log_manual_switch {
    my $status = shift;
    my $is_on = shift;
    my $last = get_last_entry($status);
    if ($last && $is_on != $last->[1]) {
        # Change has been manualy in between the interval. Add an approx history entry
        update_status($status,$is_on,"manual",estimate_manual_time($status));
    }   
}

sub update_status {
    my $status = shift;
    my $is_on = shift;
    my $mode = shift;
    my $time = shift || time;
    my $label = shift;
    my $hist = $status->{hist};
    push @{$hist},[ $time, $is_on, $mode, $label];
    info($is_on ? "On " : "Off"," -- ",$mode, $label ? ": " . $label : "");
}

sub estimate_manual_time {
    my $status = shift;
    my $last_hist = get_last_entry($status);
    if ($last_hist) {
        my $now = time;
        my $last = $last_hist->[0];
        my $calc = $now - $MANUAL_DELTA;
        return $calc > $last ? $calc : $now - int(($now - $last) / 2);
    } else {
        return time - $MANUAL_DELTA;
    }
}

sub get_last_entry {
    my $status = shift;
    if ($status) {
        my $hist = $status->{hist};
        return  $hist && @$hist ? $hist->[$#{$hist}] : undef;
    }
    return undef;
}

sub check_on_period {
    my ($min,$hour,$wd) = (localtime)[1,2,6];
    my $day = qw(Sun Mon Tue Wed Thu Fri Sat)[$wd];
    my $periods = $LAMP_ON_TIME_TABLE->{$day};
    for my $period (@$periods) {
        my ($low,$high) = @$period;
        my ($lh,$lm) = split(/:/,$low);
        my ($hh,$hm) = split(/:/,$high);
        my $m = $hour * 60 + $min;
        return 1 if $m >= ($lh * 60 + $lm) && $m <= ($hh * 60 + $hm);
    }
    return 0;
}

sub lamp_on_for_too_long {
    my $status = shift;
    
    # Check if the lamp was on for more than max time in the duration now - max
    # time + 1 hour
    my $current = time;
    my $low_time = $current - $LAMP_MAX_TIME - $LAMP_REST_TIME;
    my $on_time = 0;
    my $hist = $status->{hist};
    my $i = $#{$hist};
    while ($current > $low_time && $i >= 0) {
        my $t = $hist->[$i]->[0];
        $on_time += $current - $t if $hist->[$i]->[1];
        $current = $t;
        $i--;
    }
    if ($on_time >= $LAMP_MAX_TIME) {
        info("Lamp was on for " . $on_time . "s in the last " . ($LAMP_MAX_TIME + $LAMP_REST_TIME) . "s and is switched off now"); 
        return 1;
    } else {
        return 0;
    }
}

sub read_config_file {
    my $file = shift;
    open (F,$file) || die "Cannot read config file ",$file,": ",$!;
    my $config = join "",<F>;
    close F;
    eval $config;
    die "Error evaluating $config: ",$@ if $@;    
}

sub delete_trigger {
    my $status = shift;
    delete $status->{trigger_mark};
    delete $status->{trigger_label};
}

sub set_trigger {
    my $status = shift;
    my $label = shift;
    $status->{trigger_mark} = 1;
    $status->{trigger_label} = $label;
}

sub has_trigger {
    return shift->{trigger_mark};
}

sub trigger_label {
    return shift->{trigger_label};
}

# ====================================================
# Status file handling including locking

my $status_fh;

sub fetch_status {
    open ($status_fh,"+<$STATUS_FILE") || die "Cannot open $STATUS_FILE: $!";
    $status = fd_retrieve($status_fh) || die "Cannot read $STATUS_FILE: $!";
    flock($status_fh,2);
    return $status;
}


sub store_status {
    my $status = shift;
    
    # Truncate history if necessary
    truncate_hist($status);
    # Store status and unlock
    seek($status_fh, 0, 0); truncate($status_fh, 0);
    store_fd $status,$status_fh;
    close $status_fh;    
}

sub truncate_hist {
    my $status = shift;

    my $hist = $status->{hist};
    my $len = scalar(@$hist);
    splice @$hist,0,$len - $MAX_HISTORY_ENTRIES if $len > $MAX_HISTORY_ENTRIES;
    $status->{hist} = $hist;
}

# ==========================================================================
# Customize the following call and class in order to use a different 
# switch than AVM AHA's
sub open_lamp {
    my $config = shift;
    my $name = shift || $config->{id};
    return new Lamp($name,
                    $config->{host},
                    $config->{password},
                    $config->{user});
}

sub close_lamp {
    my $lamp = shift;
    $lamp->logout();
}

package Lamp;

use AHA;

sub new { 
    my $class = shift;
    my $name = shift;
    my $host = shift;
    my $password = shift;
    my $user = shift;

    my $aha = new AHA($host,$password,$user);
    my $switch = new AHA::Switch($aha,$name);
    
    my $self = {
                aha => $aha,
                switch => $switch
               };
    return bless $self,$class;
}

sub is_on {
    shift->{switch}->is_on();
}

sub on { 
    shift->{switch}->on();
}

sub off { 
    shift->{switch}->off();
}

sub logout {
    shift->{aha}->logout();
}

=head1 LICENSE

lava_lampl.pl is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

lava_lamp.pl is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with lava_lamp.pl.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

roland@cpan.org

=cut

