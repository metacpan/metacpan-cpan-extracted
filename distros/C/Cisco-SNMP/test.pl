#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;
use Test::Simple tests => 59;
use ExtUtils::MakeMaker qw(prompt);

my $NUM_TESTS = 59;

use Cisco::SNMP::ARP;
# use Cisco::SNMP::Config; # NO TESTS
use Cisco::SNMP::CPU;
use Cisco::SNMP::Entity;
use Cisco::SNMP::Image;
use Cisco::SNMP::Interface;
use Cisco::SNMP::IP;
use Cisco::SNMP::Line;
use Cisco::SNMP::Memory;
# use Cisco::SNMP::Password; # TESTS in t\16-Cisco-SNMP-Password.t
use Cisco::SNMP::ProxyPing;
use Cisco::SNMP::Sensor;
use Cisco::SNMP::System;

#########################

print <<STOP;

  Cisco::SNMP needs a router with SNMP enabled
  to perform the full set of tests.  Please provide a
  router hostname or IP address and the SNMP read/write
  community string at the following prompts to continue.

  To continue without running the tests (if perhaps a
  router is not available), simply press 'Enter'.


STOP

my $router = prompt("Router (hostname or IP address)  : ", '');

if ($router eq '') {
    for (1..$NUM_TESTS) {
        ok(1, "Skipping test ...")
    }
    exit
}

my $community = prompt("SNMP read/write Community string : ", '');

if ($community eq '') {
    for (1..$NUM_TESTS) {
        ok(1, "Skipping test ...")
    }
    exit
}

print "\n";
#########################

my $cm;
my $error;

# Create Session
    if (defined($cm = Cisco::SNMP::CPU->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session (New) [$error]")
    }

# Session check
    ok (($cm->{'_SESSION_'}->{'_hostname'} eq $router)
    && ($cm->{'_SESSION_'}->{'_security'}->{'_community'} eq $community),
    "Session (Hostname and community correct)");

# Check Net::SNMP session
    if (defined(my $session = $cm->session())) {
        ok($session =~ /^Net::SNMP=HASH/, "Session (Net::SNMP)")
    } else {
        $error = $cm->error;
        ok(0, "Session (Net::SNMP) [$error]")
    }
    $cm->close;

#ARP
    if (defined($cm = Cisco::SNMP::ARP->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session ARP (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session ARP (New) [$error]")
    }
    if (defined(my $arp = $cm->arp_info())) {
        ok($arp->arpIfIndex(0) =~ /^\d+$/, "ARP (IfIndex)");
        ok($cm->get_arpIfIndex($arp->arpIfIndex(0),$arp->arpNetAddress(0)) =~ /^\d+$/, "ARP Direct get_ (IfIndex)");
        my $DONE = 0;
        for (0..$#{$arp}) {
            if ($arp->arpType($_) eq 'DYNAMIC') {
                my $a = $arp->arpIfIndex($_);
                if (defined($cm->arp_clear($arp->arpIfIndex($_),$arp->arpNetAddress($_)))) {
                    ok(1, "ARP arp_clear")
                } else {
                    my $error = $cm->error;
                    if ($error =~ /^No response from remote host/) {
                        ok(1, "ARP arp_clear ?our IP? [$error]")
                    } else {
                        ok(0, "ARP arp_clear [$error]")
                    }
                }
                $DONE = 1;
                last
            }
        }
        if (!$DONE) {
            ok(1, "Skipping ARP arp_clear ... no DYNAMIC")
        }
    } else {
        for (1..3) {
            ok(1, "Skipping ARP tests ... no arp-cache")
        }
    }
    $cm->close;

# CPU
    if (defined($cm = Cisco::SNMP::CPU->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session CPU (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session CPU (New) [$error]")
    }

    if (defined(my $cpu = $cm->cpu_info())) {
        ok($cpu->cpu5min(0) ne '', "CPU (info)")
    } else {
        $error = $cm->error;
        ok(0, "CPU (info) [$error]")
    }
    $cm->close;

# Image
    if (defined($cm = Cisco::SNMP::Image->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session Image (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session Image (New) [$error]")
    }

    if (defined(my $image = $cm->image_info())) {
        ok($image->imageString(0) eq $cm->get_imageString(1), "imageString = get_imageString");
        ok($image->imageBegin, "imageBegin");
    } else {
        for (1..2) {
            ok(1, "Skipping Image tests ... not available")
        }
    }
    $cm->close;

# Interface admin up/down
    if (defined($cm = Cisco::SNMP::Interface->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session Interface (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session Interface (New) [$error]")
    }

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
    my $ifs;
    if (defined($ifs = $cm->interface_info())) {
        ok(1, "Interface (info)")
    } else {
        $error = $cm->error;
        ok(0, "Interface (info) [$error]")
    }

# Interface get by name
    my $OK = 1;
    my $key = ( sort keys %{$ifs} )[0];
    if (!defined(my $ifname = $cm->interface_getbyname($ifs->{$key}->{Description}))) {
        $OK = 0
    }
    ok($OK, "Interface (get by name)");

# Interface get by index
    $OK = 1;
    if (!defined(my $ifname = $cm->interface_getbyindex($ifs->{$key}->{Index}))) {
        $OK = 0
    }
    ok($OK, "Interface (get by index)");

#Interface Metrics
    if (defined($ifs = $cm->interface_metrics(-interface => $key, -metrics => ['octets', 'multiCasts']))) {
        $OK = 1;
        for (keys(%{$ifs})) {
            if (!defined($ifs->ifInMulticasts($_)) ||
                !defined($ifs->ifOutMulticasts($_)) ||
                !defined($ifs->ifInOctets($_)) ||
                !defined($ifs->ifOutOctets($_)) ||
                defined($ifs->ifInBroadcasts($_)) ||
                defined($ifs->ifOutBroadcasts($_))) {
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
    if (defined($ifs = $cm->interface_utilization(-interface => $key, -polling => 3, -metrics => ['octets', 'BroadCasts']))) {
        $OK = 1;
        for (keys(%{$ifs})) {
            if (defined($ifs->ifInMulticasts($_)) ||
                defined($ifs->ifOutMulticasts($_)) ||
                !defined($ifs->ifInOctets($_)) ||
                !defined($ifs->ifOutOctets($_)) ||
                !defined($ifs->ifInBroadcasts($_)) ||
                !defined($ifs->ifOutBroadcasts($_))) {
                $OK = 0;
                last
            }
        }
        ok($OK, "Interface (utilization)")
    } else {
        $error = $cm->error;
        ok(0, "Interface (utilization) [$error]")
    }
    $cm->close;

# IP
    if (defined($cm = Cisco::SNMP::IP->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session IP (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session IP (New) [$error]")
    }

    if (defined(my $ip = $cm->ip_info())) {
        my $ttl;
        ok($ip->ipDefaultTTL == ($ttl = $cm->get_ipDefaultTTL), "ipDefaultTTL = get_ipDefaultTTL");
        $cm->set_ipDefaultTTL(45);
        ok($cm->get_ipDefaultTTL == 45, "set_ipDefaultTTL");
        $cm->set_ipDefaultTTL($ttl);
        ok($cm->get_ipDefaultTTL == $ttl, "set_ipDefaultTTL (return)");
    } else {
        for (1..3) {
            ok(1, "Skipping IP tests ... not available")
        }
    }
    $cm->close;

# Lines
    if (defined($cm = Cisco::SNMP::Line->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session Line (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session Line (New) [$error]")
    }

# Lines number of
    if (defined(my $line = $cm->line_numberof())) {
        ok($line =~ /^\d+$/, "Line (number of)")
    } else {
        $error = $cm->error;
        ok(0, "Line (number of) [$error]")
    }

# Lines default clear
    if (defined(my $line = $cm->line_clear())) {
        $line = "@{$line}";
        ok($line =~ /^[\d+].+$/, "Line (clear default all)")
    } else {
        $error = $cm->error;
        ok(0, "Line (clear default all) [$error]")
    }

# Lines clear range
    if (defined(my $line = $cm->line_clear('2-4,6'))) {
        $line = "@{$line}";
        ok($line eq '2 3 4 6', "Line (clear range)")
    } else {
        $error = $cm->error;
        ok(0, "Line (clear range) [$error]")
    }

# Line info
    if (defined(my $line = $cm->line_info())) {
        ok($line->lineNumber(0) ne '', "Line (info)")
    } else {
        $error = $cm->error;
        ok(0, "Line (info) [$error]")
    }

# Line default message
    if (defined(my $line = $cm->line_message())) {
        $line = "@{$line}";
        ok($line eq 'ALL', "Line (default message)")
    } else {
        $error = $cm->error;
        ok(0, "Line (default message) [$error]")
    }

# Line provide message
    if (defined(my $line = $cm->line_message('New Test Message'))) {
        $line = "@{$line}";
        ok($line eq 'ALL', "Line (provide message)")
    } else {
        $error = $cm->error;
        ok(0, "Line (provide message) [$error]")
    }

# Line provide message lines
    if (defined(my $line = $cm->line_message(
        lines   => '2-4,6',
        message => 'New Test Message'))) {
        $line = "@{$line}";
        ok($line eq '2 3 4 6', "Line (provide message lines)")
    } else {
        $error = $cm->error;
        ok(0, "Line (provide message lines) [$error]")
    }
    $cm->close;

# Memory
    if (defined($cm = Cisco::SNMP::Memory->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session Memory (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session Memory (New) [$error]")
    }

    my $mem;
    if (defined($mem = $cm->memory_info())) {
        ok($mem->memName(0) ne '', "Memory (info)")
    } else {
        $error = $cm->error;
        ok(0, "Memory (info) [$error]")
    }
    
# Memory Direct Get
    if ($mem->memName(0) eq $cm->get_memName(1)) {
        ok(1, "Memory Direct get_")
    } else {
        $error = $cm->error;
        ok(0, "Memory Direct get_ [$error]")
    }

# Proxy Ping
    if (defined($cm = Cisco::SNMP::ProxyPing->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session ProxyPing (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session ProxyPing (New) [$error]")
    }

    my $dest;
    # Default localhost
    if (defined(my $ping = $cm->proxy_ping())) {
        $dest = $ping->{'_params_'}->{'host'};
        ok($ping->ppSent == 1, "Proxy Ping (default localhost)")
    } else {
        $error = $cm->error;
        ok(0, "Proxy Ping (default localhost) [$error]")
    }

    # Provide destination
    if (defined(my $ping = $cm->proxy_ping($router))) {
        ok(($ping->ppSent == 1) &&
           ($ping->{'_params_'}->{'host'} ne $dest),
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
        ok(($ping->ppSent == 5) &&
           ($ping->{'_params_'}->{'host'} ne $dest) &&
           ($ping->{'_params_'}->{'size'} == 255) &&
           ($ping->{'_params_'}->{'count'} == 5) &&
           ($ping->{'_params_'}->{'wait'} == 13) &&
           ($ping->{'_params_'}->{'vrf'} eq 'SomeNameVRF'),
        "Proxy Ping (provide params)")
    } else {
        $error = $cm->error;
        ok(0, "Proxy Ping (provide params) [$error]")
    }
    $cm->close;

# System
    if (defined($cm = Cisco::SNMP::System->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session System (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session System (New) [$error]")
    }

    my $sysinfo;
    if (defined($sysinfo = $cm->system_info())) {
        ok($sysinfo->sysDescr =~ /^Cisco(.*)Version(.*)/, "System Info (description)");
        ok($sysinfo->sysObjectID    =~ /^1\.3\.6\.1\.4\.1\.9\.1\.\d+$/, "System Info (objectID)");
        ok($sysinfo->sysUpTime      =~ /\d+/, "System Info (uptime)");
        ok(defined($sysinfo->sysContact), "System Info (contact)");
        ok($sysinfo->sysName        =~ //, "System Info (name)");
        ok(defined($sysinfo->sysLocation), "System Info (location)");
        my $svc = "@{$sysinfo->sysServices}";
        ok($svc =~ /^\w+[\s+\w+]*$/, "System Info (services (string))");
        ok($sysinfo->sysServices(1) =~ /^\d+$/, "System Info (services (number))");
        ok($sysinfo->sysOSVersion   =~ /\d+/, "System Info (version)");
    } else {
        $error = $cm->error;
        ok(0, "System Info () [$error]");
        for (1..8) {
            ok(0, "System Info ()")
        }
    }
    
# System direct get
    ok ($sysinfo->sysObjectID eq $cm->get_sysObjectID, "System Direct get_");
    my $sysName = $sysinfo->sysName;
    ok ((my $name = $cm->set_sysName('CiscoMgmtTest')) eq 'CiscoMgmtTest', "System Direct set_");
    $cm->set_sysName($sysName);
    ok ($sysName eq $cm->get_sysName, "System Name back to normal");
    $cm->close;

#Entity
    if (defined($cm = Cisco::SNMP::Entity->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session Entity (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session Entity (New) [$error]")
    }

    if (defined(my $inventory = $cm->entity_info())) {
        ok($inventory->entityName(0) ne '', "Entity Info");
    } else {
        $error = $cm->error;
        ok(0, "Entity Info () [$error]")
    }
    $cm->close();
    ok(1, "Session Close");

#Sensor
    if (defined($cm = Cisco::SNMP::Sensor->new(
        hostname  => $router,
        community => $community))) {
        ok(1, "Session Sensor (New)")
    } else {
        $error = $cm->error;
        ok(0, "Session Sensor (New) [$error]")
    }

    if (defined(my $sensor = $cm->sensor_info())) {
        my $key = (sort keys %{$sensor})[0];
        ok($sensor->sensType($key) ne '', "Sensor Info");
    } else {
        $error = $cm->error;
        if ($error eq "Cannot get sensor `Type' info") {
            ok(1, "Sensor Info ?not supported? [$error]")
        } else {
            ok(0, "Sensor Info () [$error]")
        }
    }
    $cm->close();
    ok(1, "Session Close");
