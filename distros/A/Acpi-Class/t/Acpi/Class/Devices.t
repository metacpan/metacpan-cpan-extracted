#!/usr/bin/env perl 
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use strict;
use warnings;
use utf8;
use 5.010;
use Acpi::Class::Devices;
use List::Compare;
use Test::More tests => 1;

# Check that the elements of $dir are correctly read
my @dirs = qw( examples lib t);
my $devices = Acpi::Class::Devices->new( dir => $Bin, pattern => qr/\w/ )->devices;
my $comparison = List::Compare->new(\@dirs, $devices);
my $equivalent = $comparison->is_LequivalentR;

ok ( $equivalent = 1, "Acpi::Class::Devices reads subdirectories");

done_testing( 1 );
