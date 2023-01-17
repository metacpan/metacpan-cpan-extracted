# vim: set sw=4 ts=4 tw=78 et si filetype=perl:

use Test::More;
use App::Iptables2Dot;

my ($i2d,$dg);

$i2d = new App::Iptables2Dot();

eval {
    $i2d->read_iptables_file('t/iptables-save/github-issue-4.txt');
};
like($@,qr/^$/,"Unknown option: uid-owner");

done_testing();
