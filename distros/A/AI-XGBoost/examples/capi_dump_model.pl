use strict;
use warnings;
use 5.010;
use Data::Dumper;
use AI::XGBoost::CAPI qw(:all);

my $dtrain = XGDMatrixCreateFromFile('agaricus.txt.train');
my $dtest = XGDMatrixCreateFromFile('agaricus.txt.test');

my $booster = XGBoosterCreate([$dtrain]);
XGBoosterUpdateOneIter($booster, 1, $dtrain);

my $json_model_with_stats = XGBoosterDumpModelEx($booster, "featmap.txt", 1, "json");

say Dumper $json_model_with_stats;

XGBoosterFree($booster);
XGDMatrixFree($dtrain);
XGDMatrixFree($dtest);





