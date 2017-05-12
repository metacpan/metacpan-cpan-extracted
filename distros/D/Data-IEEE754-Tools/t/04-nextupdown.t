########################################################################
# Verifies the following functions:
#   :ulp
#       nextUp(v)
#       nextDown(v)
#   (other :ulp tests in other .t files)
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
        SWITCHFUNCTION: foreach ($fn) {
            my $val = /^nextDown$/ ? - $v : $v;     # choose nextUp or nextDown
            if( $val != $val ) {    # NAN
                diag( "DEBUG($fn): IS NAN\t" . to_dec_floatingpoint($val) );
                last SWITCHFUNCTION;
            } else {
                diag( "DEBUG($fn): ISN'T NAN\t" . to_dec_floatingpoint($val) );
            }
            my $h754 = hexstr754_from_double($val);
            diag( "DEBUG($fn): h754 = $h754" );
            if($h754 eq '7FF0000000000000') { diag "DEBUG($fn): +INF => return +INF"; last SWITCHFUNCTION; }
            if($h754 eq 'FFF0000000000000') { diag "DEBUG($fn): -INF => return -HUGE"; last SWITCHFUNCTION; }
            if($h754 eq '8000000000000000') { diag "DEBUG($fn): +INF => return +DENORM_1"; last SWITCHFUNCTION; }
            my ($msb,$lsb) = Data::IEEE754::Tools::arr2x32b_from_double($val);
            diag( "DEBUG($fn): msb,lsb = $msb,$lsb" );
            $lsb += ($msb & 0x80000000) ? -1.0 : +1.0;
            diag( "DEBUG($fn): adjust lsb => $lsb" );
            if($lsb == 4_294_967_296.0) {
                $lsb = 0.0;
                $msb += ($msb & 0x80000000) ? -1.0 : +1.0;
                diag( "DEBUG($fn): LSB OVERFLOW => msb,lsb = $msb,$lsb" );
            } elsif ($lsb == -1.0) {
                $msb += ($msb & 0x80000000) ? -1.0 : +1.0;
                diag( "DEBUG($fn): LSB==-1.0 => msb,lsb = $msb,$lsb" );
            }
            diag( "DEBUG($fn): ALMOST msb,lsb = $msb,$lsb" );
            $msb &= 0xFFFFFFFF;     # v0.011_001: potential bugfix: ensure 32bit MSB <https://rt.cpan.org/Public/Bug/Display.html?id=116006>
            $lsb &= 0xFFFFFFFF;     # v0.011_001: potential bugfix: ensure 32bit MSB <https://rt.cpan.org/Public/Bug/Display.html?id=116006>
            diag( "DEBUG($fn): MASKED msb,lsb = $msb,$lsb" );
            diag( "DEBUG($fn): FINAL HEXSTR = " .sprintf('%08X%08X', $msb, $lsb ));
            diag( "DEBUG($fn): FINAL DOUBLE = " .to_dec_floatingpoint(hexstr754_to_double( sprintf '%08X%08X', $msb, $lsb )));
            diag( "DEBUG($fn): FINAL NEG DOUBLE = " .to_dec_floatingpoint(-hexstr754_to_double( sprintf '%08X%08X', $msb, $lsb )))
                if (/^nextDown$/);
            last SWITCHFUNCTION;
        }
        diag '';
    }
    note '-'x80;
}

my @tests = ();

# now test all the nextUp()
push @tests, { func => 'nextUp', arg => '0000000000000000', expect => hexstr754_to_double('0000000000000001'),    name => "nextUp(POS_ZERO)" };
push @tests, { func => 'nextUp', arg => '8000000000000000', expect => hexstr754_to_double('0000000000000001'),    name => "nextUp(NEG_ZERO)" };
push @tests, { func => 'nextUp', arg => '0000000000000001', expect => hexstr754_to_double('0000000000000002'),    name => "nextUp(POS_DENORM_1)" };
push @tests, { func => 'nextUp', arg => '8000000000000001', expect => hexstr754_to_double('8000000000000000'),    name => "nextUp(NEG_DENORM_1)" };
push @tests, { func => 'nextUp', arg => '000FFFFFFFFFFFFF', expect => hexstr754_to_double('0010000000000000'),    name => "nextUp(POS_DENORM_F)" };
push @tests, { func => 'nextUp', arg => '800FFFFFFFFFFFFF', expect => hexstr754_to_double('800FFFFFFFFFFFFE'),    name => "nextUp(NEG_DENORM_F)" };
push @tests, { func => 'nextUp', arg => '0010000000000000', expect => hexstr754_to_double('0010000000000001'),    name => "nextUp(POS_NORM_x1x0)" };
push @tests, { func => 'nextUp', arg => '8010000000000000', expect => hexstr754_to_double('800FFFFFFFFFFFFF'),    name => "nextUp(NEG_NORM_x1x0)" };
push @tests, { func => 'nextUp', arg => '001FFFFFFFFFFFFE', expect => hexstr754_to_double('001FFFFFFFFFFFFF'),    name => "nextUp(POS_NORM_x1xE)" };
push @tests, { func => 'nextUp', arg => '801FFFFFFFFFFFFE', expect => hexstr754_to_double('801FFFFFFFFFFFFD'),    name => "nextUp(NEG_NORM_x1xE)" };
push @tests, { func => 'nextUp', arg => '001FFFFFFFFFFFFF', expect => hexstr754_to_double('0020000000000000'),    name => "nextUp(POS_NORM_x1xF)" };
push @tests, { func => 'nextUp', arg => '801FFFFFFFFFFFFF', expect => hexstr754_to_double('801FFFFFFFFFFFFE'),    name => "nextUp(NEG_NORM_x1xF)" };
push @tests, { func => 'nextUp', arg => '034FFFFFFFFFFFFF', expect => hexstr754_to_double('0350000000000000'),    name => "nextUp(POS_NORM_x34F)" };
push @tests, { func => 'nextUp', arg => '834FFFFFFFFFFFFF', expect => hexstr754_to_double('834FFFFFFFFFFFFE'),    name => "nextUp(NEG_NORM_x34F)" };
push @tests, { func => 'nextUp', arg => '0350000000000000', expect => hexstr754_to_double('0350000000000001'),    name => "nextUp(POS_NORM_x350)" };
push @tests, { func => 'nextUp', arg => '8350000000000000', expect => hexstr754_to_double('834FFFFFFFFFFFFF'),    name => "nextUp(NEG_NORM_x350)" };
push @tests, { func => 'nextUp', arg => '7FE0000000000000', expect => hexstr754_to_double('7FE0000000000001'),    name => "nextUp(POS_NORM_xFx0)" };
push @tests, { func => 'nextUp', arg => 'FFE0000000000000', expect => hexstr754_to_double('FFDFFFFFFFFFFFFF'),    name => "nextUp(NEG_NORM_xFx0)" };
push @tests, { func => 'nextUp', arg => '7FEFFFFFFFFFFFFF', expect => hexstr754_to_double('7FF0000000000000'),    name => "nextUp(POS_NORM_xFxF)" };
push @tests, { func => 'nextUp', arg => 'FFEFFFFFFFFFFFFF', expect => hexstr754_to_double('FFEFFFFFFFFFFFFE'),    name => "nextUp(NEG_NORM_xFxF)" };
push @tests, { func => 'nextUp', arg => '7FF0000000000000', expect => hexstr754_to_double('7FF0000000000000'),    name => "nextUp(POS_INF)" };
push @tests, { func => 'nextUp', arg => 'FFF0000000000000', expect => hexstr754_to_double('FFEFFFFFFFFFFFFF'),    name => "nextUp(NEG_INF)" };
push @tests, { func => 'nextUp', arg => '7FF0000000000001', expect => hexstr754_to_double('7FF0000000000001'),    name => "nextUp(POS_SNAN_01)" };
push @tests, { func => 'nextUp', arg => 'FFF0000000000001', expect => hexstr754_to_double('FFF0000000000001'),    name => "nextUp(NEG_SNAN_01)" };
push @tests, { func => 'nextUp', arg => '7FF7FFFFFFFFFFFF', expect => hexstr754_to_double('7FF7FFFFFFFFFFFF'),    name => "nextUp(POS_SNAN_7F)" };
push @tests, { func => 'nextUp', arg => 'FFF7FFFFFFFFFFFF', expect => hexstr754_to_double('FFF7FFFFFFFFFFFF'),    name => "nextUp(NEG_SNAN_7F)" };
push @tests, { func => 'nextUp', arg => '7FF8000000000000', expect => hexstr754_to_double('7FF8000000000000'),    name => "nextUp(POS_IND_80)" };
push @tests, { func => 'nextUp', arg => 'FFF8000000000000', expect => hexstr754_to_double('FFF8000000000000'),    name => "nextUp(NEG_IND_80)" };
push @tests, { func => 'nextUp', arg => '7FF8000000000001', expect => hexstr754_to_double('7FF8000000000001'),    name => "nextUp(POS_QNAN_81)" };
push @tests, { func => 'nextUp', arg => 'FFF8000000000001', expect => hexstr754_to_double('FFF8000000000001'),    name => "nextUp(NEG_QNAN_81)" };
push @tests, { func => 'nextUp', arg => '7FFFFFFFFFFFFFFF', expect => hexstr754_to_double('7FFFFFFFFFFFFFFF'),    name => "nextUp(POS_QNAN_FF)" };
push @tests, { func => 'nextUp', arg => 'FFFFFFFFFFFFFFFF', expect => hexstr754_to_double('FFFFFFFFFFFFFFFF'),    name => "nextUp(NEG_QNAN_FF)" };

# now test all the nextDown()
push @tests, { func => 'nextDown', arg => '0000000000000000', expect => hexstr754_to_double('8000000000000001'),    name => "nextDown(POS_ZERO)" };
push @tests, { func => 'nextDown', arg => '8000000000000000', expect => hexstr754_to_double('8000000000000001'),    name => "nextDown(NEG_ZERO)" };
push @tests, { func => 'nextDown', arg => '0000000000000001', expect => hexstr754_to_double('0000000000000000'),    name => "nextDown(POS_DENORM_1)" };
push @tests, { func => 'nextDown', arg => '8000000000000001', expect => hexstr754_to_double('8000000000000002'),    name => "nextDown(NEG_DENORM_1)" };
push @tests, { func => 'nextDown', arg => '000FFFFFFFFFFFFF', expect => hexstr754_to_double('000FFFFFFFFFFFFE'),    name => "nextDown(POS_DENORM_F)" };
push @tests, { func => 'nextDown', arg => '800FFFFFFFFFFFFF', expect => hexstr754_to_double('8010000000000000'),    name => "nextDown(NEG_DENORM_F)" };
push @tests, { func => 'nextDown', arg => '0010000000000000', expect => hexstr754_to_double('000FFFFFFFFFFFFF'),    name => "nextDown(POS_NORM_x1x0)" };
push @tests, { func => 'nextDown', arg => '8010000000000000', expect => hexstr754_to_double('8010000000000001'),    name => "nextDown(NEG_NORM_x1x0)" };
push @tests, { func => 'nextDown', arg => '001FFFFFFFFFFFFE', expect => hexstr754_to_double('001FFFFFFFFFFFFD'),    name => "nextDown(POS_NORM_x1xE)" };
push @tests, { func => 'nextDown', arg => '801FFFFFFFFFFFFE', expect => hexstr754_to_double('801FFFFFFFFFFFFF'),    name => "nextDown(NEG_NORM_x1xE)" };
push @tests, { func => 'nextDown', arg => '001FFFFFFFFFFFFF', expect => hexstr754_to_double('001FFFFFFFFFFFFE'),    name => "nextDown(POS_NORM_x1xF)" };
push @tests, { func => 'nextDown', arg => '801FFFFFFFFFFFFF', expect => hexstr754_to_double('8020000000000000'),    name => "nextDown(NEG_NORM_x1xF)" };
push @tests, { func => 'nextDown', arg => '034FFFFFFFFFFFFF', expect => hexstr754_to_double('034FFFFFFFFFFFFE'),    name => "nextDown(POS_NORM_x34F)" };
push @tests, { func => 'nextDown', arg => '834FFFFFFFFFFFFF', expect => hexstr754_to_double('8350000000000000'),    name => "nextDown(NEG_NORM_x34F)" };
push @tests, { func => 'nextDown', arg => '0350000000000000', expect => hexstr754_to_double('034FFFFFFFFFFFFF'),    name => "nextDown(POS_NORM_x350)" };
push @tests, { func => 'nextDown', arg => '8350000000000000', expect => hexstr754_to_double('8350000000000001'),    name => "nextDown(NEG_NORM_x350)" };
push @tests, { func => 'nextDown', arg => '7FE0000000000000', expect => hexstr754_to_double('7FDFFFFFFFFFFFFF'),    name => "nextDown(POS_NORM_xFx0)" };
push @tests, { func => 'nextDown', arg => 'FFE0000000000000', expect => hexstr754_to_double('FFE0000000000001'),    name => "nextDown(NEG_NORM_xFx0)" };
push @tests, { func => 'nextDown', arg => '7FEFFFFFFFFFFFFF', expect => hexstr754_to_double('7FEFFFFFFFFFFFFE'),    name => "nextDown(POS_NORM_xFxF)" };
push @tests, { func => 'nextDown', arg => 'FFEFFFFFFFFFFFFF', expect => hexstr754_to_double('FFF0000000000000'),    name => "nextDown(NEG_NORM_xFxF)" };
push @tests, { func => 'nextDown', arg => '7FF0000000000000', expect => hexstr754_to_double('7FEFFFFFFFFFFFFF'),    name => "nextDown(POS_INF)" };
push @tests, { func => 'nextDown', arg => 'FFF0000000000000', expect => hexstr754_to_double('FFF0000000000000'),    name => "nextDown(NEG_INF)" };
push @tests, { func => 'nextDown', arg => '7FF0000000000001', expect => hexstr754_to_double('7FF0000000000001'),    name => "nextDown(POS_SNAN_01)" };
push @tests, { func => 'nextDown', arg => 'FFF0000000000001', expect => hexstr754_to_double('FFF0000000000001'),    name => "nextDown(NEG_SNAN_01)" };
push @tests, { func => 'nextDown', arg => '7FF7FFFFFFFFFFFF', expect => hexstr754_to_double('7FF7FFFFFFFFFFFF'),    name => "nextDown(POS_SNAN_7F)" };
push @tests, { func => 'nextDown', arg => 'FFF7FFFFFFFFFFFF', expect => hexstr754_to_double('FFF7FFFFFFFFFFFF'),    name => "nextDown(NEG_SNAN_7F)" };
push @tests, { func => 'nextDown', arg => '7FF8000000000000', expect => hexstr754_to_double('7FF8000000000000'),    name => "nextDown(POS_IND_80)" };
push @tests, { func => 'nextDown', arg => 'FFF8000000000000', expect => hexstr754_to_double('FFF8000000000000'),    name => "nextDown(NEG_IND_80)" };
push @tests, { func => 'nextDown', arg => '7FF8000000000001', expect => hexstr754_to_double('7FF8000000000001'),    name => "nextDown(POS_QNAN_81)" };
push @tests, { func => 'nextDown', arg => 'FFF8000000000001', expect => hexstr754_to_double('FFF8000000000001'),    name => "nextDown(NEG_QNAN_81)" };
push @tests, { func => 'nextDown', arg => '7FFFFFFFFFFFFFFF', expect => hexstr754_to_double('7FFFFFFFFFFFFFFF'),    name => "nextDown(POS_QNAN_FF)" };
push @tests, { func => 'nextDown', arg => 'FFFFFFFFFFFFFFFF', expect => hexstr754_to_double('FFFFFFFFFFFFFFFF'),    name => "nextDown(NEG_QNAN_FF)" };

# plan and execute
plan tests => scalar @tests;

fntest( $_->{func}, $_->{arg}, $_->{expect}, $_->{name}, $_->{todo} ) foreach @tests;

exit;
