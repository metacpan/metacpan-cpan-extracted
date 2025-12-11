#!/usr/bin/perl

use warnings;
use strict;
use threads;

use constant TRUE  => 1;
use constant FALSE => 0;

use BACnet::Device;
use Data::Dumper;

# -------------------------------------------------------------------
# Command-line arguments
# -------------------------------------------------------------------

if (@ARGV < 2) {
    die "Usage: $0 <local_ip> <host_ip>\n";
}

my $local_ip = $ARGV[0];
my $host_ip  = $ARGV[1];

# -------------------------------------------------------------------

sub dump {
    my ( $device, $message, @rest ) = @_;
    print "Received message:\n", Dumper($message), "\n";
}

# Device initialization
my %args = (
    addr  => $local_ip,
    sport => 47808,
    id    => 42,
);

# ReadProperty request parameters
my %args_read_prop = (
    obj_type             => 0,
    obj_instance         => 2,
    property_identifier  => 85,
    property_array_index => undef,
    host_ip              => $host_ip,
    peer_port            => 47808,
    on_response          => \&dump,
);

my $mydevice = BACnet::Device->new(%args);

$mydevice->read_property(%args_read_prop);

$mydevice->run;