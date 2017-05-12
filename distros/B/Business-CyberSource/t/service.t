use strict;
use warnings;
use Test::More;

use Module::Runtime qw( use_module );

my $s0 = new_ok( use_module('Business::CyberSource::RequestPart::Service'));

can_ok( $s0, 'serialize' );

my %expected_serialized = ( run => 'true' );

is_deeply( $s0->serialize, \%expected_serialized, 'serialized' );

done_testing;
