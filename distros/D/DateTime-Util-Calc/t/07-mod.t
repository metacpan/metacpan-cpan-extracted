#!perl
use Test::More tests => 18;
BEGIN
{
    use_ok("DateTime::Util::Calc", qw(mod amod));
}

sub is_mod { is(mod($_[0], $_[1]), $_[2], "$_[0] mod $_[1] is $_[2]") }

# definitions from calendarical caluculations
is_mod(9, 5, 4);
is_mod(-9, 5, 1);
is_mod(9, -5, -1);
is_mod(-9, -5, -4);

is_mod(5 / 3, 3 / 4, 1 / 6);
#is_mod(Math::BigFloat->new(5) / 3, Math::BigFloat->new(3) / 4, Math::BigFloat->new(1) / 6);

# Arbitrary testing

is( mod( 10, 2 ), 0 );
is( mod( 11, 2 ), 1 );
is( mod( 10, 4 ), 2 );
is( amod( 10, 2 ), 2 );
is( amod( 11, 2 ), 1 );
is( amod( 10, 4 ), 2 );

is_mod(Math::BigFloat->new('10.123'), 2, 0.123);
is_mod(Math::BigFloat->new('-10.123'), 2, 1.877);

is( sprintf( '%0.3f', mod( 10.123, 2)), 0.123 );
is( sprintf( '%0.3f', mod( -10.123, 2)), 1.877);
is( mod( -10, 2 ), 0 );
is( mod( -11, 2 ), 1 );


