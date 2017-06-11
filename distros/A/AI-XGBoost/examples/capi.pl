use 5.010;
use AI::XGBoost::CAPI qw(:all);

my $dtrain = XGDMatrixCreateFromFile('agaricus.txt.train');
my $dtest = XGDMatrixCreateFromFile('agaricus.txt.test');

my ($rows, $cols) = (XGDMatrixNumRow($dtrain), XGDMatrixNumCol($dtrain));
say "Train dimensions: $rows, $cols";

my $booster = XGBoosterCreate([$dtrain]);

for my $iter (0 .. 10) {
    XGBoosterUpdateOneIter($booster, $iter, $dtrain);
}

my $predictions = XGBoosterPredict($booster, $dtest, 0, 0);
# say join "\n", @$predictions;

XGBoosterFree($booster);
XGDMatrixFree($dtrain);
XGDMatrixFree($dtest);




