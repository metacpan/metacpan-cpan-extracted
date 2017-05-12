########################################################################
# Verifies the following functions:
#   :ulp
#       ulp(v)
#       toggle_ulp(v)
#   remaining :ulp features in next test(s)
########################################################################
use 5.006;
use warnings;
use strict;
use Test::More;
use Data::IEEE754::Tools qw/:raw754 :ulp :floatingpoint/;

my ($h,$u,$v);

sub fntest {
    my $fn = shift;
    my $f = \&{$fn};                        # strict refs doesn't allow &$fn(arg) directly
    my $h = shift;
    my $x = shift;
    my $v = hexstr754_to_double($h);
    my $u = $f->($v); # works strict refs    # &$fn($v) and $fn->($v) fail strict refs; &$f($v) would also work
    $u = '<undef>' unless defined $u;
    my $n = shift || "$fn(0x$h => $v)";
    my $tada = shift;
    my $r = undef;
    note '';
    note "===== ${n} =====";
    if($tada) {
        TODO: {
            local $TODO = $tada;
            if( $u =~ /(?:NAN|INF|IND)/i or $x =~ /(?:NAN|INF|IND)/i ) {
                $r = cmp_ok( $u, 'eq', $x, $n );
            } else {
                $r = cmp_ok( $u, '==', $x, $n );
            }
        }
    } else {
            if( $u =~ /(?:NAN|INF|IND)/i or $x =~ /(?:NAN|INF|IND)/i ) {
                $r = cmp_ok( $u, 'eq', $x, $n );
            } else {
                $r = cmp_ok( $u, '==', $x, $n );
            }
    }
    unless($r) {
        diag '';
        diag "$n:";
        diag sprintf "ORIGINAL: hex(%-30s) = %s", to_dec_floatingpoint($v), $h;
        diag sprintf "EXPECT:   hex(%-30s) = %s", to_dec_floatingpoint($x), hexstr754_from_double($x);
        diag sprintf "ANSWER:   hex(%-30s) = %s", to_dec_floatingpoint($u), hexstr754_from_double($u);
        diag '';
    }
    note '-'x80;
}

my @tests = ();

# need to ensure toggle_ulp() works before testing ulp(), since the latter calls the former
push @tests, { func => 'toggle_ulp', arg => '0000000000000000', expect => hexstr754_to_double('0000000000000001'),    name => "toggle_ulp(POS_ZERO)" };   # the smallest you can add to zero is smallest denormal
push @tests, { func => 'toggle_ulp', arg => '8000000000000000', expect => hexstr754_to_double('8000000000000001'),    name => "toggle_ulp(NEG_ZERO)" };
push @tests, { func => 'toggle_ulp', arg => '0000000000000001', expect => hexstr754_to_double('0000000000000000'),    name => "toggle_ulp(POS_DENORM_1)" };
push @tests, { func => 'toggle_ulp', arg => '8000000000000001', expect => hexstr754_to_double('0000000000000000'),    name => "toggle_ulp(NEG_DENORM_1)" };
push @tests, { func => 'toggle_ulp', arg => '000FFFFFFFFFFFFF', expect => hexstr754_to_double('000FFFFFFFFFFFFE'),    name => "toggle_ulp(POS_DENORM_F)" };
push @tests, { func => 'toggle_ulp', arg => '800FFFFFFFFFFFFF', expect => hexstr754_to_double('800FFFFFFFFFFFFE'),    name => "toggle_ulp(NEG_DENORM_F)" };
push @tests, { func => 'toggle_ulp', arg => '0010000000000000', expect => hexstr754_to_double('0010000000000001'),    name => "toggle_ulp(POS_NORM_x1x0)" };
push @tests, { func => 'toggle_ulp', arg => '8010000000000000', expect => hexstr754_to_double('8010000000000001'),    name => "toggle_ulp(NEG_NORM_x1x0)" };
push @tests, { func => 'toggle_ulp', arg => '001FFFFFFFFFFFFF', expect => hexstr754_to_double('001FFFFFFFFFFFFE'),    name => "toggle_ulp(POS_NORM_x1xF)" };
push @tests, { func => 'toggle_ulp', arg => '801FFFFFFFFFFFFF', expect => hexstr754_to_double('801FFFFFFFFFFFFE'),    name => "toggle_ulp(NEG_NORM_x1xF)" };
push @tests, { func => 'toggle_ulp', arg => '7FE0000000000000', expect => hexstr754_to_double('7FE0000000000001'),    name => "toggle_ulp(POS_NORM_xFx0)" };
push @tests, { func => 'toggle_ulp', arg => 'FFE0000000000000', expect => hexstr754_to_double('FFE0000000000001'),    name => "toggle_ulp(NEG_NORM_xFx0)" };
push @tests, { func => 'toggle_ulp', arg => '7FEFFFFFFFFFFFFF', expect => hexstr754_to_double('7FEFFFFFFFFFFFFE'),    name => "toggle_ulp(POS_NORM_xFxF)" };
push @tests, { func => 'toggle_ulp', arg => 'FFEFFFFFFFFFFFFF', expect => hexstr754_to_double('FFEFFFFFFFFFFFFE'),    name => "toggle_ulp(NEG_NORM_xFxF)" };
push @tests, { func => 'toggle_ulp', arg => '7FF0000000000000', expect => hexstr754_to_double('7FF0000000000000'),    name => "toggle_ulp(POS_INF)" };
push @tests, { func => 'toggle_ulp', arg => 'FFF0000000000000', expect => hexstr754_to_double('FFF0000000000000'),    name => "toggle_ulp(NEG_INF)" };
push @tests, { func => 'toggle_ulp', arg => '7FF0000000000001', expect => hexstr754_to_double('7FF0000000000001'),    name => "toggle_ulp(POS_SNAN_01)" };
push @tests, { func => 'toggle_ulp', arg => 'FFF0000000000001', expect => hexstr754_to_double('FFF0000000000001'),    name => "toggle_ulp(NEG_SNAN_01)" };
push @tests, { func => 'toggle_ulp', arg => '7FF7FFFFFFFFFFFF', expect => hexstr754_to_double('7FF7FFFFFFFFFFFF'),    name => "toggle_ulp(POS_SNAN_7F)" };
push @tests, { func => 'toggle_ulp', arg => 'FFF7FFFFFFFFFFFF', expect => hexstr754_to_double('FFF7FFFFFFFFFFFF'),    name => "toggle_ulp(NEG_SNAN_7F)" };
push @tests, { func => 'toggle_ulp', arg => '7FF8000000000000', expect => hexstr754_to_double('7FF8000000000000'),    name => "toggle_ulp(POS_IND_80)" };
push @tests, { func => 'toggle_ulp', arg => 'FFF8000000000000', expect => hexstr754_to_double('FFF8000000000000'),    name => "toggle_ulp(NEG_IND_80)" };
push @tests, { func => 'toggle_ulp', arg => '7FF8000000000001', expect => hexstr754_to_double('7FF8000000000001'),    name => "toggle_ulp(POS_QNAN_81)" };
push @tests, { func => 'toggle_ulp', arg => 'FFF8000000000001', expect => hexstr754_to_double('FFF8000000000001'),    name => "toggle_ulp(NEG_QNAN_81)" };
push @tests, { func => 'toggle_ulp', arg => '7FFFFFFFFFFFFFFF', expect => hexstr754_to_double('7FFFFFFFFFFFFFFF'),    name => "toggle_ulp(POS_QNAN_FF)" };
push @tests, { func => 'toggle_ulp', arg => 'FFFFFFFFFFFFFFFF', expect => hexstr754_to_double('FFFFFFFFFFFFFFFF'),    name => "toggle_ulp(NEG_QNAN_FF)" };

# now test all the ulp()
push @tests, { func => 'ulp', arg => '0000000000000000', expect => hexstr754_to_double('0000000000000001'),    name => "ulp(POS_ZERO)" };
push @tests, { func => 'ulp', arg => '8000000000000000', expect => hexstr754_to_double('0000000000000001'),    name => "ulp(NEG_ZERO)" };
push @tests, { func => 'ulp', arg => '0000000000000001', expect => hexstr754_to_double('0000000000000001'),    name => "ulp(POS_DENORM_1)" };
push @tests, { func => 'ulp', arg => '8000000000000001', expect => hexstr754_to_double('0000000000000001'),    name => "ulp(NEG_DENORM_1)" };
push @tests, { func => 'ulp', arg => '000FFFFFFFFFFFFF', expect => hexstr754_to_double('0000000000000001'),    name => "ulp(POS_DENORM_F)" };
push @tests, { func => 'ulp', arg => '800FFFFFFFFFFFFF', expect => hexstr754_to_double('0000000000000001'),    name => "ulp(NEG_DENORM_F)" };
push @tests, { func => 'ulp', arg => '0010000000000000', expect => hexstr754_to_double('0000000000000001'),    name => "ulp(POS_NORM_x1x0)" };
push @tests, { func => 'ulp', arg => '8010000000000000', expect => hexstr754_to_double('0000000000000001'),    name => "ulp(NEG_NORM_x1x0)" };
push @tests, { func => 'ulp', arg => '001FFFFFFFFFFFFF', expect => hexstr754_to_double('0000000000000001'),    name => "ulp(POS_NORM_x1xF)" };
push @tests, { func => 'ulp', arg => '801FFFFFFFFFFFFF', expect => hexstr754_to_double('0000000000000001'),    name => "ulp(NEG_NORM_x1xF)" };
push @tests, { func => 'ulp', arg => '034FFFFFFFFFFFFF', expect => hexstr754_to_double('0008000000000000'),    name => "ulp(POS_NORM_x34F): last denormal ulp" };
push @tests, { func => 'ulp', arg => '834FFFFFFFFFFFFF', expect => hexstr754_to_double('0008000000000000'),    name => "ulp(NEG_NORM_x34F): last denormal ulp" };
push @tests, { func => 'ulp', arg => '0350000000000000', expect => hexstr754_to_double('0010000000000000'),    name => "ulp(POS_NORM_x350): first normal ulp" };
push @tests, { func => 'ulp', arg => '8350000000000000', expect => hexstr754_to_double('0010000000000000'),    name => "ulp(NEG_NORM_x350): first normal ulp" };
push @tests, { func => 'ulp', arg => '7FE0000000000000', expect => hexstr754_to_double('7CA0000000000000'),    name => "ulp(POS_NORM_xFx0)" };
push @tests, { func => 'ulp', arg => 'FFE0000000000000', expect => hexstr754_to_double('7CA0000000000000'),    name => "ulp(NEG_NORM_xFx0)" };
push @tests, { func => 'ulp', arg => '7FEFFFFFFFFFFFFF', expect => hexstr754_to_double('7CA0000000000000'),    name => "ulp(POS_NORM_xFxF)" };
push @tests, { func => 'ulp', arg => 'FFEFFFFFFFFFFFFF', expect => hexstr754_to_double('7CA0000000000000'),    name => "ulp(NEG_NORM_xFxF)" };
push @tests, { func => 'ulp', arg => '7FF0000000000000', expect => hexstr754_to_double('7FF0000000000000'),    name => "ulp(POS_INF)" };
push @tests, { func => 'ulp', arg => 'FFF0000000000000', expect => hexstr754_to_double('FFF0000000000000'),    name => "ulp(NEG_INF)" };
push @tests, { func => 'ulp', arg => '7FF0000000000001', expect => hexstr754_to_double('7FF0000000000001'),    name => "ulp(POS_SNAN_01)" };
push @tests, { func => 'ulp', arg => 'FFF0000000000001', expect => hexstr754_to_double('FFF0000000000001'),    name => "ulp(NEG_SNAN_01)" };
push @tests, { func => 'ulp', arg => '7FF7FFFFFFFFFFFF', expect => hexstr754_to_double('7FF7FFFFFFFFFFFF'),    name => "ulp(POS_SNAN_7F)" };
push @tests, { func => 'ulp', arg => 'FFF7FFFFFFFFFFFF', expect => hexstr754_to_double('FFF7FFFFFFFFFFFF'),    name => "ulp(NEG_SNAN_7F)" };
push @tests, { func => 'ulp', arg => '7FF8000000000000', expect => hexstr754_to_double('7FF8000000000000'),    name => "ulp(POS_IND_80)" };
push @tests, { func => 'ulp', arg => 'FFF8000000000000', expect => hexstr754_to_double('FFF8000000000000'),    name => "ulp(NEG_IND_80)" };
push @tests, { func => 'ulp', arg => '7FF8000000000001', expect => hexstr754_to_double('7FF8000000000001'),    name => "ulp(POS_QNAN_81)" };
push @tests, { func => 'ulp', arg => 'FFF8000000000001', expect => hexstr754_to_double('FFF8000000000001'),    name => "ulp(NEG_QNAN_81)" };
push @tests, { func => 'ulp', arg => '7FFFFFFFFFFFFFFF', expect => hexstr754_to_double('7FFFFFFFFFFFFFFF'),    name => "ulp(POS_QNAN_FF)" };
push @tests, { func => 'ulp', arg => 'FFFFFFFFFFFFFFFF', expect => hexstr754_to_double('FFFFFFFFFFFFFFFF'),    name => "ulp(NEG_QNAN_FF)" };

# plan and execute
plan tests => scalar @tests;
fntest( $_->{func}, $_->{arg}, $_->{expect}, $_->{name}, $_->{todo} ) foreach @tests;

exit;
