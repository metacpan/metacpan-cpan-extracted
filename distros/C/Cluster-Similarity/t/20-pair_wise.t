use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Cluster::Similarity;

my $class1 = [ { a => 1, b => 1, c => 1 }, { d => 1, e => 1, f => 1 } ];
my $class2 = [ { a => 1, b => 1 }, { c => 1, d => 1, e => 1 }, { f => 1 } ];

my $sim = Cluster::Similarity->new();

$sim->load_data($class1, $class2);

my $tp = $sim->true_positives();

ok($tp eq 2, 'true positives');

my $pairs_1 = $sim->pairs_classification_1();

ok($pairs_1 eq 6, 'number of pairs in classification 1');

my $pairs_2 = $sim->pairs_classification_2();

ok($pairs_2 eq 4, 'number of pairs in classification 2');

my $recall = sprintf('%.3f', $sim->pair_wise_recall());
my $exp_recall = sprintf('%.3f', 1/3);
ok($recall eq $exp_recall, "pair-wise recall: got $recall, expected $exp_recall");

my $prec = sprintf('%.3f', $sim->pair_wise_precision());
my $exp_prec = sprintf('%.3f', 1/2);
ok($prec eq $exp_prec, "pair-wise precision: got $prec, expected $exp_prec");

my $fscore = sprintf('%.3f', $sim->pair_wise_fscore());
my $exp_fscore = sprintf('%.3f', 2/5);
ok($fscore eq $exp_fscore, "pair-wise f-score: got $fscore, expected $exp_fscore");

diag("Precision, recall and f-score for twice the first classification\n");

$sim->load_data($class1, $class1);

$recall = sprintf('%.3f', $sim->pair_wise_recall());
ok($recall == 1, "Recall: $recall\n");

$prec = sprintf('%.3f', $sim->pair_wise_precision());
ok($prec == 1, "Precision: $prec\n");

$fscore = sprintf('%.3f', $sim->pair_wise_fscore());
ok($fscore == 1, "f-score: $fscore\n");

diag("Precision, recall and f-score for twice the second classification\n");

$sim->load_data($class2, $class2);

$recall = sprintf('%.3f', $sim->pair_wise_recall());
ok($recall == 1, "Recall: $recall\n");

$prec = sprintf('%.3f', $sim->pair_wise_precision());
ok($prec == 1, "Precision: $prec\n");

$fscore = sprintf('%.3f', $sim->pair_wise_fscore());
ok($fscore == 1, "f-score: $fscore\n");


1;
