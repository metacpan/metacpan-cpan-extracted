#!perl

use v5.10;
use Test::More;

use CVSS::v3;

my $base_score    = 7.4;
my $vector_string = 'CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H';

my $cvss = CVSS::v3->new(version => '3.1');

$cvss->attackVector('ADJACENT_NETWORK');
$cvss->attackComplexity('LOW');
$cvss->privilegesRequired('LOW');
$cvss->userInteraction('REQUIRED');
$cvss->scope('UNCHANGED');
$cvss->confidentialityImpact('HIGH');
$cvss->integrityImpact('HIGH');
$cvss->availabilityImpact('HIGH');

$cvss->calculate_score();

cmp_ok($cvss->base_score,       '==', $base_score,    "Check base score ($base_score)");
cmp_ok($cvss->to_vector_string, 'eq', $vector_string, "Check vector string ($vector_string)");

cmp_ok($cvss->attackVector,          'eq', 'ADJACENT_NETWORK', 'Check attackVector value');
cmp_ok($cvss->attackComplexity,      'eq', 'LOW',              'Check attackComplexity value');
cmp_ok($cvss->privilegesRequired,    'eq', 'LOW',              'Check privilegesRequired value');
cmp_ok($cvss->userInteraction,       'eq', 'REQUIRED',         'Check userInteraction value');
cmp_ok($cvss->scope,                 'eq', 'UNCHANGED',        'Check scope value');
cmp_ok($cvss->confidentialityImpact, 'eq', 'HIGH',             'Check confidentialityImpact value');
cmp_ok($cvss->integrityImpact,       'eq', 'HIGH',             'Check integrityImpact value');
cmp_ok($cvss->availabilityImpact,    'eq', 'HIGH',             'Check availabilityImpact value');

cmp_ok($cvss->M('AV'), 'eq', 'A', 'Check AV metric value');
cmp_ok($cvss->M('AC'), 'eq', 'L', 'Check AC metric value');
cmp_ok($cvss->M('PR'), 'eq', 'L', 'Check PR metric value');
cmp_ok($cvss->M('UI'), 'eq', 'R', 'Check UI metric value');
cmp_ok($cvss->M('S'),  'eq', 'U', 'Check S metric value');
cmp_ok($cvss->M('C'),  'eq', 'H', 'Check C metric value');
cmp_ok($cvss->M('I'),  'eq', 'H', 'Check I metric value');
cmp_ok($cvss->M('A'),  'eq', 'H', 'Check A metric value');

done_testing();
