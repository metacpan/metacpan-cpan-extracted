use strict;
use warnings;

use Test::More 'no_plan';
use Test::LongString;

BEGIN { use_ok('Chemistry::Harmonia') };
use Chemistry::Harmonia qw(:all);

##### Test prepare_mix() #####

my $ce = [ [ 'O2', 'K' ], [ 'K2O', 'Na2O2', 'K2O2', 'KO2' ] ];
my $real = [ 'K', 'O2', 'K2O2', 'KO2' ];
my $k = { 'K' => 2, 'K2O2' => 1, 'KO2' => 0 };

is_string( prepare_mix( $ce, { 'coefficients' => $k } ),
    'O2 + 2 K == K2O + Na2O2 + 1 K2O2 + 0 KO2' );

is_string( prepare_mix( $ce, { 'coefficients' => $k, 'substances' => $real } ),
    'O2 + 2 K == 1 K2O2 + 0 KO2' );

exit;
