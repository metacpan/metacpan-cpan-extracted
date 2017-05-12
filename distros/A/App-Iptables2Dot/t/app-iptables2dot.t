
# vim: set sw=4 ts=4 tw=78 et si filetype=perl:

use Test::More;
use App::Iptables2Dot;

my ($i2d,$dg);

$i2d = new App::Iptables2Dot();

$i2d->read_iptables_file('t/iptables-save/test.txt');

# Test omitting of TARGET jumps in the output.
#
# first: show target jumps
#
$dg = $i2d->dot_graph( {showrules => 1,}, 'nat' );
like($dg, qr/POSTROUTING:R0:e -> MASQUERADE:w;$/ms, 'got MASQ target');
like($dg, qr/POSTROUTING:R1:e -> SNAT:name:w;$/ms, 'got SNAT target');
like($dg, qr/PREROUTING:R0:e -> DNAT:name:w;$/ms, 'got DNAT target');
#
# second: omit some target jumps but not all
#
$dg = $i2d->dot_graph( {showrules => 1,
        omittargets => 'SNAT,DNAT',
    }, 'nat' );
like($dg, qr/POSTROUTING:R0:e -> MASQUERADE:w;$/ms, 'got MASQ target');
unlike($dg, qr/POSTROUTING:R1:e -> SNAT:name:w;$/ms, 'got SNAT target');
unlike($dg, qr/PREROUTING:R0:e -> DNAT:name:w;$/ms, 'got DNAT target');

# Test show unused CHAINS
#
# first: omit them
#
$dg = $i2d->dot_graph( {}, 'filter' );
like($dg, qr/{ rank = source; "FORWARD"; }$/ms,
    'did not get unused chains');
unlike($dg, qr/INPUT \[shape=none,margin=0,/ms, 'did not get unused chains');
unlike($dg, qr/OUTPUT \[shape=none,margin=0,/ms, 'did not get unused chains');
#
# second: show them
#
$dg = $i2d->dot_graph( {showunusednodes => 1}, 'filter' );
like($dg, qr/{ rank = source; "FORWARD"; "INPUT"; "OUTPUT"; }$/ms,
    'got unused chains');
like($dg, qr/INPUT \[shape=none,margin=0,/ms, 'got unused chains');
like($dg, qr/OUTPUT \[shape=none,margin=0,/ms, 'got unused chains');

done_testing();
