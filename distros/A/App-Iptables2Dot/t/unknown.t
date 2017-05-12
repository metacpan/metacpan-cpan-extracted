
# vim: set sw=4 ts=4 tw=78 et si filetype=perl:

use Test::More;
use App::Iptables2Dot;

my ($i2d,$dg);

$i2d = new App::Iptables2Dot();

eval {
    $i2d->read_iptables_file('t/iptables-save/unknown.txt');
};
like($@, qr/unknown argument in rule: --unknown-opt arg --jump LOG/ms,
    'got unknown option in rule');

App::Iptables2Dot::add_optdef('unknown-opt=s');

eval {
    $i2d->read_iptables_file('t/iptables-save/unknown.txt');
};
unlike($@, qr/unknown argument in rule: --unknown-opt arg --jump LOG/ms,
    'know previous unknown option');

$dg = $i2d->dot_graph( {showrules => 1, }, 'filter' );
like($dg, qr/FORWARD:R0:e -> LOG:name:w;$/ms, 'understand unknown option');

done_testing();
