#!/usr/bin/perl

use warnings;
use strict;
use threads;

use constant TRUE  => 1;
use constant FALSE => 0;

use BACnet::Device;
use Data::Dumper;

# ---------------------------------------------------------------
# Command-line arguments
# ---------------------------------------------------------------
if (@ARGV < 2) {
    die "Usage: $0 <local_ip> <host_ip>\n";
}

my $local_ip = $ARGV[0];
my $host_ip  = $ARGV[1];

# ---------------------------------------------------------------

sub dump {
    my ( $device, $message, @rest ) = @_;
    print "get message: ", Dumper($message), "\n";
}

my %args = (
    addr  => $local_ip,
    sport => 47808,
    id    => 42,
);

my $mydevice = BACnet::Device->new(%args);

# ---------------------------------------------------------------
# Subscription definitions
# ---------------------------------------------------------------

my %args1 = (
    obj_type                      => 0,
    obj_inst                      => 1,
    issue_confirmed_notifications => FALSE,
    lifetime_in                   => 100,
    host_ip                       => $host_ip,
    peer_port                     => 47808,
    on_COV                        => \&dump,
    on_response                   => \&dump,
);

my %args2 = (
    obj_type                      => 0,
    obj_inst                      => 2,
    issue_confirmed_notifications => TRUE,
    lifetime_in                   => 100,
    host_ip                       => $host_ip,
    peer_port                     => 47808,
    on_COV                        => \&dump,
    on_response                   => \&dump,
);

sub another_sub {
    my ( $device, $message, @rest ) = @_;
    $device->subscribe(%args1);
}

# ---------------------------------------------------------------
# Perform subscriptions
# ---------------------------------------------------------------

my ($new_sub,  $error)  = $mydevice->subscribe(%args1);
my ($new_sub2, $error2) = $mydevice->subscribe(%args2);

# If needed, we could print errors:
# print "Error: $error\n"   if defined $error;
# print "Error2: $error2\n" if defined $error2;

# ---------------------------------------------------------------

$mydevice->run;