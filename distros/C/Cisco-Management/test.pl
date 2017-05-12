#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;
use Test::Simple tests => 35;
use ExtUtils::MakeMaker qw(prompt);

my $NUM_TESTS = 35;

use Cisco::Management;
ok(1, "Loading Module"); # If we made it this far, we're ok.

#########################

print <<STOP;

  Cisco::Management needs a router with SNMP enabled
  to perform the full set of tests.  Please provide a
  router hostname or IP address and the SNMP read/write
  community string at the following prompts to continue.

  To continue without running the tests (if perhaps a
  router is not available), simply press 'Enter'.


STOP

my $router = prompt("Router (hostname or IP address)  : ", '');

if ($router eq '') {
    for (2..$NUM_TESTS) {
        ok(1, "Skipping test ...")
    }
    exit
}

my $community = prompt("SNMP read/write Community string : ", '');

if ($community eq '') {
    for (2..$NUM_TESTS) {
        ok(1, "Skipping test ...")
    }
    exit
}

print "\n";
#########################

my $cm;
my $error;

# Create Session
    # Session
    if (defined($cm = Cisco::Management->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session (New) [$error]")
    }

    # Check
    ok (($cm->{'_SESSION_'}->{'_hostname'} eq $router)
    && ($cm->{'hostname'} eq $router)
    && ($cm->{'_SESSION_'}->{'_security'}->{'_community'} eq $community)
    && ($cm->{'community'} eq $community),
    "Session (Hostname and community correct)");

# Check Net::SNMP session
    if (defined(my $session = $cm->session())) {
        ok($session =~ /^Net::SNMP=HASH/, "Session (Net::SNMP)")
    } else {
        $error = $cm->error;
        ok(0, "Session (Net::SNMP) [$error]")
    }

# CPU
    # CPU Info
    if (defined(my $cpu = $cm->cpu_info())) {
        ok($cpu->[0]->{'5min'} ne '', "CPU (info)")
    } else {
        $error = $cm->error;
        ok(0, "CPU (info) [$error]")
    }

# Interface admin up/down
    if (defined(my $ifs = $cm->interface_updown(100000))) {
        ok(0, "Interface (admin up fake ifIndex)")
    } else {
        $error = $cm->error;
        ok($error eq 'Failed to UP interface 100000', "Interface (admin up fake ifIndex)")
    }

    if (defined(my $ifs = $cm->interface_updown(
        interface => '100000-100002',
        operation => 'down'))) {
        ok(0, "Interface (admin down fake range)")
    } else {
        $error = $cm->error;
        ok($error eq 'Failed to DOWN interface 100000', "Interface (admin down fake range)")
    }

    if (defined(my $ifs = $cm->interface_updown(
        interface => '100000 to 100002'))) {
        ok(0, "Interface (admin up bad range)")
    } else {
        $error = $cm->error;
        ok($error eq "Invalid range format `100000 to 100002'", "Interface (admin up bad range)")
    }

# Interface Info
    # If Info
    my $ifs;
    if (defined($ifs = $cm->interface_info())) {
        ok(1, "Interface (info)")
    } else {
        $error = $cm->error;
        ok(0, "Interface (info) [$error]")
    }

    # Interface get by name
    my $OK = 1;
    for (keys(%{$ifs})) {
        if (!defined(my $ifname = $cm->interface_getbyname($ifs->{$_}->{Description}))) {
            $OK = 0;
            last
        }
    }
    ok($OK, "Interface (get by name)");

    # Interface get by index
    $OK = 1;
    for (keys(%{$ifs})) {
        if (!defined(my $ifname = $cm->interface_getbyindex($ifs->{$_}->{Index}))) {
            $OK = 0;
            last
        }
    }
    ok($OK, "Interface (get by index)");

#Interface Metrics
    if (defined($ifs = $cm->interface_metrics(-metrics => ['octets', 'multiCasts']))) {
        $OK = 1;
        for (keys(%{$ifs})) {
            if (!defined($ifs->{$_}->{InMulticasts}) ||
                !defined($ifs->{$_}->{OutMulticasts}) ||
                !defined($ifs->{$_}->{InOctets}) ||
                !defined($ifs->{$_}->{OutOctets}) ||
                defined($ifs->{$_}->{InBroadcasts}) ||
                defined($ifs->{$_}->{OutBroadcasts})) {
                $OK = 0;
                last
            }
        }
        ok($OK, "Interface (metrics)")
    } else {
        $error = $cm->error;
        ok(0, "Interface (metrics) [$error]")
    }

#Interface Util
    if (defined($ifs = $cm->interface_utilization(-polling => 3, -metrics => ['octets', 'BroadCasts']))) {
        $OK = 1;
        for (keys(%{$ifs})) {
            if (defined($ifs->{$_}->{InMulticasts}) ||
                defined($ifs->{$_}->{OutMulticasts}) ||
                !defined($ifs->{$_}->{InOctets}) ||
                !defined($ifs->{$_}->{OutOctets}) ||
                !defined($ifs->{$_}->{InBroadcasts}) ||
                !defined($ifs->{$_}->{OutBroadcasts})) {
                $OK = 0;
                last
            }
        }
        ok($OK, "Interface (utilization)")
    } else {
        $error = $cm->error;
        ok(0, "Interface (utilization) [$error]")
    }

# Lines
    # Number of
    if (defined(my $line = $cm->line_numberof())) {
        ok($line =~ /^\d+$/, "Line (number of)")
    } else {
        $error = $cm->error;
        ok(0, "Line (number of) [$error]")
    }

    # Default clear
    if (defined(my $line = $cm->line_clear())) {
        $line = "@{$line}";
        ok($line =~ /^[\d+].+$/, "Line (clear default all)")
    } else {
        $error = $cm->error;
        ok(0, "Line (clear default all) [$error]")
    }

    # Clear range
    if (defined(my $line = $cm->line_clear('2-4,6'))) {
        $line = "@{$line}";
        ok($line eq '2 3 4 6', "Line (clear range)")
    } else {
        $error = $cm->error;
        ok(0, "Line (clear range) [$error]")
    }

    # Line info
    if (defined(my $line = $cm->line_info())) {
        ok($line->{0}->{'Number'} ne '', "Line (info)")
    } else {
        $error = $cm->error;
        ok(0, "Line (info) [$error]")
    }

    # Default message
    if (defined(my $line = $cm->line_message())) {
        $line = "@{$line}";
        ok($line eq 'ALL', "Line (default message)")
    } else {
        $error = $cm->error;
        ok(0, "Line (default message) [$error]")
    }

    # Provide message
    if (defined(my $line = $cm->line_message('New Test Message'))) {
        $line = "@{$line}";
        ok($line eq 'ALL', "Line (provide message)")
    } else {
        $error = $cm->error;
        ok(0, "Line (provide message) [$error]")
    }

    # Provide message lines
    if (defined(my $line = $cm->line_message(
        lines   => '2-4,6',
        message => 'New Test Message'))) {
        $line = "@{$line}";
        ok($line eq '2 3 4 6', "Line (provide message lines)")
    } else {
        $error = $cm->error;
        ok(0, "Line (provide message lines) [$error]")
    }

# Memory
    # Memory Info
    if (defined(my $mem = $cm->memory_info())) {
        ok($mem->[0]->{'Name'} ne '', "Memory (info)")
    } else {
        $error = $cm->error;
        ok(0, "Memory (info) [$error]")
    }

# Proxy Ping
    my $dest;
    # Default localhost
    if (defined(my $ping = $cm->proxy_ping())) {
        $dest = $ping->{'_PROXYPING_'}{'_params_'}->{'host'};
        ok($ping->proxy_ping_sent == 1, "Proxy Ping (default localhost)")
    } else {
        $error = $cm->error;
        ok(0, "Proxy Ping (default localhost) [$error]")
    }

    # Provide destination
    if (defined(my $ping = $cm->proxy_ping($router))) {
        ok(($ping->proxy_ping_sent == 1) &&
           ($ping->{'_PROXYPING_'}{'_params_'}->{'host'} ne $dest),
        "Proxy Ping (provide destination)")
    } else {
        $error = $cm->error;
        ok(0, "Proxy Ping (provide destination) [$error]")
    }

    # Provide params
    if (defined(my $ping = $cm->proxy_ping(
        host  => $router,
        size  => 255,
        count => 5,
        wait  => 13,
        vrf   => 'SomeNameVRF'))) {
        ok(($ping->proxy_ping_sent == 5) &&
           ($ping->{'_PROXYPING_'}{'_params_'}->{'host'} ne $dest) &&
           ($ping->{'_PROXYPING_'}{'_params_'}->{'size'} == 255) &&
           ($ping->{'_PROXYPING_'}{'_params_'}->{'count'} == 5) &&
           ($ping->{'_PROXYPING_'}{'_params_'}->{'wait'} == 13) &&
           ($ping->{'_PROXYPING_'}{'_params_'}->{'vrf'} eq 'SomeNameVRF'),
        "Proxy Ping (provide params)")
    } else {
        $error = $cm->error;
        ok(0, "Proxy Ping (provide params) [$error]")
    }

# System
    # Get system info
    if (defined(my $sysinfo = $cm->system_info())) {
        ok($sysinfo->system_info_description =~ /^Cisco(.*)Version(.*)/, "System Info (description)");
        ok($sysinfo->system_info_objectID    =~ /^1\.3\.6\.1\.4\.1\.9\.1\.\d+$/, "System Info (objectID)");
        ok($sysinfo->system_info_uptime      =~ /\d+/, "System Info (uptime)");
        ok(defined($sysinfo->system_info_contact), "System Info (contact)");
        ok($sysinfo->system_info_name        =~ //, "System Info (name)");
        ok(defined($sysinfo->system_info_location), "System Info (location)");
        my $svc = "@{$sysinfo->system_info_services}";
        ok($svc =~ /^\w+[\s+\w+]*$/, "System Info (services (string))");
        ok($sysinfo->system_info_services(1) =~ /^\d+$/, "System Info (services (number))");
        ok($sysinfo->system_info_osversion   =~ /\d+/, "System Info (version)");
    } else {
        $error = $cm->error;
        ok(0, "System Info () [$error]");
        for (1..8) {
            ok(0, "System Info ()")
        }
    }

    # Get system inventory
    if (defined(my $inventory = $cm->system_inventory())) {
        ok($inventory->[0]->{Name} ne '', "System Inventory");
    } else {
        $error = $cm->error;
        ok(0, "System Inventory () [$error]")
    }

# END
    # Close
    $cm->close();
    ok(1, "Session Close");
