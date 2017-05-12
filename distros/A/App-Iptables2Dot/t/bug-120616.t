
# vim: set sw=4 ts=4 tw=78 et si filetype=perl:

use Test::More;
use App::Iptables2Dot;

my ($i2d,$dg);

$i2d = new App::Iptables2Dot();

$i2d->read_iptables_file('t/iptables-save/bug-120616.txt');

$dg = $i2d->dot_graph( {showrules => 1, }, 'filter' );
like($dg, qr/--comment "user chain for output"/ms, 'got comment');
like($dg, qr/--ctstate DNAT/ms, 'got ctstate');

$dg = $i2d->dot_graph( {showrules => 1, }, 'nat' );
like($dg, qr/--gid-owner 800/ms, 'got gid-owner');

$dg = $i2d->dot_graph( {showrules => 1, }, 'raw' );
like($dg, qr/--notrack/ms, 'got notrack');

done_testing();
