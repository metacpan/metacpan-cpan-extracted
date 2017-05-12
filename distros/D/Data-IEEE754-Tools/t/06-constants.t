########################################################################
# Verifies the various constant double-float values:
#   :constants
########################################################################
use 5.006;
use warnings;
use strict;
use Test::More;
use Data::IEEE754::Tools qw/:constants :floatingpoint hexstr754_to_double/;

my @tests = ();
push @tests, [ POS_ZERO           (), hexstr754_to_double('000'.'0000000000000') , 'POS_ZERO           '];
push @tests, [ POS_DENORM_SMALLEST(), hexstr754_to_double('000'.'0000000000001') , 'POS_DENORM_SMALLEST'];
push @tests, [ POS_DENORM_BIGGEST (), hexstr754_to_double('000'.'FFFFFFFFFFFFF') , 'POS_DENORM_BIGGEST '];
push @tests, [ POS_NORM_SMALLEST  (), hexstr754_to_double('001'.'0000000000000') , 'POS_NORM_SMALLEST  '];
push @tests, [ POS_NORM_BIGGEST   (), hexstr754_to_double('7FE'.'FFFFFFFFFFFFF') , 'POS_NORM_BIGGEST   '];
push @tests, [ POS_INF            (), hexstr754_to_double('7FF'.'0000000000000') , 'POS_INF            '];
push @tests, [ POS_SNAN_FIRST     (), hexstr754_to_double('7FF'.'0000000000001') , 'POS_SNAN_FIRST     '];
push @tests, [ POS_SNAN_LAST      (), hexstr754_to_double('7FF'.'7FFFFFFFFFFFF') , 'POS_SNAN_LAST      '];
push @tests, [ POS_IND            (), hexstr754_to_double('7FF'.'8000000000000') , 'POS_IND            '];
push @tests, [ POS_QNAN_FIRST     (), hexstr754_to_double('7FF'.'8000000000001') , 'POS_QNAN_FIRST     '];
push @tests, [ POS_QNAN_LAST      (), hexstr754_to_double('7FF'.'FFFFFFFFFFFFF') , 'POS_QNAN_LAST      '];
push @tests, [ NEG_ZERO           (), hexstr754_to_double('800'.'0000000000000') , 'NEG_ZERO           '];
push @tests, [ NEG_DENORM_SMALLEST(), hexstr754_to_double('800'.'0000000000001') , 'NEG_DENORM_SMALLEST'];
push @tests, [ NEG_DENORM_BIGGEST (), hexstr754_to_double('800'.'FFFFFFFFFFFFF') , 'NEG_DENORM_BIGGEST '];
push @tests, [ NEG_NORM_SMALLEST  (), hexstr754_to_double('801'.'0000000000000') , 'NEG_NORM_SMALLEST  '];
push @tests, [ NEG_NORM_BIGGEST   (), hexstr754_to_double('FFE'.'FFFFFFFFFFFFF') , 'NEG_NORM_BIGGEST   '];
push @tests, [ NEG_INF            (), hexstr754_to_double('FFF'.'0000000000000') , 'NEG_INF            '];
push @tests, [ NEG_SNAN_FIRST     (), hexstr754_to_double('FFF'.'0000000000001') , 'NEG_SNAN_FIRST     '];
push @tests, [ NEG_SNAN_LAST      (), hexstr754_to_double('FFF'.'7FFFFFFFFFFFF') , 'NEG_SNAN_LAST      '];
push @tests, [ NEG_IND            (), hexstr754_to_double('FFF'.'8000000000000') , 'NEG_IND            '];
push @tests, [ NEG_QNAN_FIRST     (), hexstr754_to_double('FFF'.'8000000000001') , 'NEG_QNAN_FIRST     '];
push @tests, [ NEG_QNAN_LAST      (), hexstr754_to_double('FFF'.'FFFFFFFFFFFFF') , 'NEG_QNAN_LAST      '];

plan tests => scalar @tests;

foreach (@tests) {
    my ($c, $x, $n) = @$_;
    my $got = to_hex_floatingpoint $c;
    my $exp = to_hex_floatingpoint $x;
    is( $got , $exp , "const: $n" );
}

exit;