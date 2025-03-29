use Test::More tests => 5;
use Test::NoWarnings;

use_ok( 'Acme::GLOINBG::Utils' );
ok( defined &Acme::GLOINBG::Utils::sum, 'sum() is defined' );

my @good_list = 1 .. 10;
is( Acme::GLOINBG::Utils::sum( @good_list), 55,
  'The sum of 1 to 10 is 55' );

my @weird_list = qw( a b c 1 2 3 123abc );
is( Acme::GLOINBG::Utils::sum( @weird_list), 129,
  'The weird sum is 129' );
