
# vim: set sw=4 ts=4 tw=78 et si filetype=perl:

use Test::More;
use App::Iptables2Dot;

my ($i2d,$dg);

$i2d = new App::Iptables2Dot();

$i2d->read_iptables_file('t/iptables-save/maiki.txt');

$dg = $i2d->dot_graph( {showrules => 1, }, 'filter' );
like($dg, qr/INPUT:R0:e -> ULOG:name:w;$/ms, 'got ULOG target');
like($dg, qr/INPUT:R1:e -> LOG_IN_SRV_ACCEPT_APPLI:name:w;$/ms,
    'got LOG_IN_SRV target');
like($dg, qr/OUTPUT:R0:e -> LOG_OUT_SRV_ACCEPT_APPLI:name:w;$/ms,
    'got LOG_IN_SRV target');

done_testing();
