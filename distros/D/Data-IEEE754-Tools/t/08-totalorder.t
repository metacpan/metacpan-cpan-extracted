########################################################################
# Verifies the following functions:
#   :info
#       totalOrder(v)
#       totalOrderMag(v)
#		compareFloatingValue(v)
#		compareFloatingMag(v)
#   other functions from info in other test files
########################################################################
use 5.006;
use warnings;
use strict;
use Test::More;
use Data::IEEE754::Tools qw/:raw754 :floatingpoint :constants :info/;

my @constants = (
    NEG_QNAN_LAST      ,
    NEG_QNAN_FIRST     ,
    NEG_IND            ,
    NEG_SNAN_LAST      ,
    NEG_SNAN_FIRST     ,
    NEG_INF            ,
    NEG_NORM_BIGGEST   ,
    NEG_NORM_SMALLEST  ,
    NEG_DENORM_BIGGEST ,
    NEG_DENORM_SMALLEST,
    NEG_ZERO           ,
    POS_ZERO           ,
    POS_DENORM_SMALLEST,
    POS_DENORM_BIGGEST ,
    POS_NORM_SMALLEST  ,
    POS_NORM_BIGGEST   ,
    POS_INF            ,
    POS_SNAN_FIRST     ,
    POS_SNAN_LAST      ,
    POS_IND            ,
    POS_QNAN_FIRST     ,
    POS_QNAN_LAST
);

sub ijQuiet($) {	    # hardcoded indexes of the array; if array changes, must change indexes
    local $_ = shift;
    /^(0|1|2|19|20|21)$/
}

sub ijSignal($) {	    # hardcoded indexes of the array; if array changes, must change indexes
    local $_ = shift;
    /^(3|4|17|18)$/
}

plan tests => (scalar @constants)**2 * 4;

my $skip_reason = '';
if( isSignalingConvertedToQuiet() ) {
    $skip_reason = 'Signaling NaN are converted to QuietNaN by your perl: ';
    eval { require Config };
    $skip_reason .= $@ ? sprintf('v%vd',$^V) : "$Config::Config{myuname}";
}

sub habs($) {
    my $h = shift;
    my $s = substr $h, 0, 1;
    $s = sprintf '%1.1X', (hex($s)&0x7);        # mask OUT sign bit
    substr $h, 0, 1, $s;
    return $h;
}
foreach my $i (0 .. $#constants) {
    my $x = $constants[$i];
    my $hx = hexstr754_from_double($x);
    my $hax = habs($hx);
    my $ax = hexstr754_to_double($hax);
    foreach my $j (0 .. $#constants) {
        my $y = $constants[$j];
        my $hy = hexstr754_from_double($y);
        my $hay = habs($hy);
        my $ay = hexstr754_to_double($hay);
        local $, = ", ";
        local $\ = "\n";
		my $skip_bool = isSignalingConvertedToQuiet() && (
                # if Signalling converted to Quiet, order will be messed up if both are NaN but one each of signal and quiet
                (ijQuiet($i) && ijSignal($j)) ||    # i quiet && j signaling
                (ijQuiet($j) && ijSignal($i))       # j quiet && i signaling
            );

		# totalOrder(x,y): x<=y ? 1 : 0;
        SKIP: {
            skip sprintf('%-25.25s(%16.16s,%16.16s): %s','totalOrder',$hx,$hy,$skip_reason), 1    if $skip_bool;
            # this will still compare either NaN to anything else (INF, NORM, SUB, ZERO), and will also compare
            # signaling to signaling and quiet to quiet

            my $got = totalOrder( $x, $y );
            my $exp = ($i <= $j) || 0;
            is( $got, $exp, sprintf('%-30.30s(%s,%s)', 'totalOrder', $hx, $hy ) );
        }

		# totalOrderMag(x,y):  |x|<=|y| ? 1 : 0;
        SKIP: {
            skip sprintf('%-25.25s(%16.16s,%16.16s): %s','totalOrderMag',$hax,$hay,$skip_reason), 1    if $skip_bool;
            # this will still compare either NaN to anything else (INF, NORM, SUB, ZERO), and will also compare
            # signaling to signaling and quiet to quiet

            my $got = totalOrderMag( $x, $y );
            my $exp = ( ($i<11 ? 21-$i : $i) <= ($j<11 ? 21-$j : $j) ) || 0;
            is( $got, $exp, sprintf('%-30.30s(%s,%s)', 'totalOrderMag', $hax, $hay ) );
        }

		# compareFloatingValue(x,y): x <=> y
        SKIP: {
            skip sprintf('%-25.25s(%16.16s,%16.16s): %s','compareFloatingValue',$hx,$hy,$skip_reason), 1    if $skip_bool;
            # this will still compare either NaN to anything else (INF, NORM, SUB, ZERO), and will also compare
            # signaling to signaling and quiet to quiet

            my $got = compareFloatingValue( $x, $y );
            my $exp = ($i <=> $j);
            is( $got, $exp, sprintf('%-30.30s(%s,%s)', 'compareFloatingValue', $hx, $hy ) );
        }

		# compareFloatingMag(x,y): |x| <=> |y|
        SKIP: {
            skip sprintf('%-25.25s(%16.16s,%16.16s): %s','compareFloatingMag',$hax,$hay,$skip_reason), 1    if $skip_bool;
            # this will still compare either NaN to anything else (INF, NORM, SUB, ZERO), and will also compare
            # signaling to signaling and quiet to quiet

            my $got = compareFloatingMag( $x, $y );
            my $exp = ($i<11 ? 21-$i : $i) <=> ($j<11 ? 21-$j : $j);
            is( $got, $exp, sprintf('%-30.30s(%s,%s)', 'compareFloatingMag', $hax, $hay ) );
        }

    }
}

exit;
