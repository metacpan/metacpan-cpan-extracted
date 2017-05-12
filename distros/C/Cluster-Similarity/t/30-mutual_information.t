use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Cluster::Similarity;

my $class1 = [ { a => 1, b => 1, c => 1 }, { d => 1, e => 1, f => 1 } ];
my $class2 = [ { a => 1, b => 1 }, { c => 1, d => 1, e => 1 }, { f => 1 } ];

my $sim = Cluster::Similarity->new();

$sim->load_data($class1, $class2);

my $mi = sprintf('%.5f', $sim->mutual_information());

my $exp_mi = 2*log(2)/log(6) + log(6/9)/log(6) + 2*log(12/9)/log(6) + log(2)/log(6);
$exp_mi = $exp_mi/6;
$exp_mi = sprintf('%.5f', $exp_mi);

#my $exp_mi = sprintf('%.5f', (3 * log(2) + log(2/3) + 2* log(4/3))/(6*log(6)));

ok($mi == $exp_mi, "mutual information: got $mi, expected $exp_mi");

$sim->load_data($class1, $class1);

$mi = sprintf('%.5f', $sim->mutual_information());

diag("MI for twice the first classification: $mi\n");

$sim->load_data($class2, $class2);

$mi = sprintf('%.5f', $sim->mutual_information());

diag("MI for twice the second classification: $mi\n");

1;
