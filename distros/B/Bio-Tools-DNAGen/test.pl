use Test;
BEGIN { plan tests => 6 };
use Bio::Tools::DNAGen;
ok(1);

my $gen = new Bio::Tools::DNAGen;

####################
$gen->set_prefix("aaa");
$gen->set_len(12);
$gen->set_gcratio(50);

ok(length(($gen->genseq)[0]), 12);
ok(calc_gcratio(($gen->genseq)[0]), 50);

####################
$gen->set_gcratio();
$gen->set_len(10);
$gen->set_mt(20);
$gen->set_prefix('aaa');

ok(($gen->genseq)[0], qr'^aaa');
ok(calc_mt(($gen->genseq)[0]), 20);

$gen->set_limit(2);
ok($gen->genseq, 2);
