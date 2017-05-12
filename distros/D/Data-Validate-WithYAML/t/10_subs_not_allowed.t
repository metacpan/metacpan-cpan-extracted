#!perl 

use strict;
use Test::More tests => 2;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new(
    $FindBin::Bin . '/test3.yml',
);

my $eval = 1;
eval {
    my $ip_ranges_ok = $validator->check_list( 'ip_ranges', ['abc'] );
    1;
} or $eval = 0;

ok !$eval;
