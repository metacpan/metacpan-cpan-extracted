# Test miscellanious functions.

use Test::More;
use ALPM;

## Test vercmp.

is(ALPM->vercmp('0.1', '0.2'), -1);
is(ALPM->vercmp('0.10', '0.2'), 1);
is(ALPM->vercmp('0.001', '0.1'), 0); # 0's are skipped
is(ALPM->vercmp('0.100', '0.2'), 1); # 100 > 2

## Test find_dbs_satisfier.

require ALPM::Conf;
ALPM::Conf->import('t/test.conf');
$foo = $alpm->find_dbs_satisfier('foo>1.0', $alpm->syncdbs);
ok $foo;
if($foo){
	is $foo->db->name, 'upgradetest';
}

## Test find_satisfier.

$p1 = $alpm->db('simpletest')->find('foo');
$p2 = $alpm->db('upgradetest')->find('foo');
ok $p1 && $p2;
if($p1 && $p2){
	$p3 = $alpm->find_satisfier('foo>1.0', $p1, $p2);
	is $p3->db->name, 'upgradetest';
}

done_testing;
