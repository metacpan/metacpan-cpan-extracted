#!perl 

use strict;
use Test::More tests => 4;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new(
    $FindBin::Bin . '/test3.yml',
    allow_subs => 1,
);

my $ip_ranges_ok = $validator->check_list( 'ip_ranges', [] );
is( $ip_ranges_ok->[0], undef );

my $ip_ranges_ok3 = $validator->check_list( 'ip_ranges', ['abc'] );
is( $ip_ranges_ok3->[0], 0 );

my $ip_ranges_ok2 = $validator->check_list( 'ip_ranges', ['8.2'] );
is( $ip_ranges_ok2->[0], 1 );
