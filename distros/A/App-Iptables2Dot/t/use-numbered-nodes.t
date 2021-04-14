# vim: set sw=4 ts=4 tw=78 et si filetype=perl:

use Test::More;
use App::Iptables2Dot;

my ($i2d,$dg);

$i2d = new App::Iptables2Dot();

$i2d->read_iptables_file('t/iptables-save/dashes.txt');

$dg = $i2d->dot_graph( {'use-numbered-nodes' => 1}, 'filter' );

like($dg, qr/node0 \[shape=none,margin=0,label=/ms, 'used numbered nodes');
like($dg, qr/node1 \[shape=none,margin=0,label=/ms, 'used numbered nodes');
like($dg, qr/node0:e -> node1:name:w/ms, 'used numbered nodes');
like($dg, qr/node1:e -> LOG:name:w/ms, 'used numbered nodes');

done_testing();

