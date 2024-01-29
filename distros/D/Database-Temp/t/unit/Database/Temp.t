#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)
# no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;

use English qw( -no_match_vars );    # Avoids regex performance
local $OUTPUT_AUTOFLUSH = 1;

use utf8;

use Test2::V0 -target => 'Database::Temp';
use Test2::Tools::Spec;
set_encoding('utf8');

# Add t/lib to @INC
use FindBin 1.51 qw( $RealBin );
use File::Spec;
my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{.}, q{../..}, 'lib' );
}
use lib "$lib_path";

describe 'method `is_available`' => sub {
    my ( $driver, $expected_availability );
    case 'DummyForTesting driver' => sub {
        $driver                = 'DummyForTesting';
        $expected_availability = 1;
    };
    case 'Missing driver' => sub {
        $driver                = 'Missing';
        $expected_availability = 0;
    };
    case 'Empty name driver' => sub {
        $driver                = q{};
        $expected_availability = 0;
    };
    case 'undef driver' => sub {
        $driver                = undef;
        $expected_availability = 0;
    };
    tests 'it works' => sub {
        my $got_availability = $CLASS->is_available( driver => $driver );
        is( $got_availability, $expected_availability, 'Expected availability returned' );
    };
};

describe "class `$CLASS`" => sub {

    tests 'it can be instantiated' => sub {
        can_ok( $CLASS, 'new' );
    };
};

done_testing;
