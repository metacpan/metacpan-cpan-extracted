use 5.010;
use AI::XGBoost::CAPI::RAW;
use FFI::Platypus;

my $silent = 0;
my ($dtrain, $dtest) = (0, 0);

AI::XGBoost::CAPI::RAW::XGDMatrixCreateFromFile('agaricus.txt.test', $silent, \$dtest);
AI::XGBoost::CAPI::RAW::XGDMatrixCreateFromFile('agaricus.txt.train', $silent, \$dtrain);

my ($rows, $cols) = (0, 0);
AI::XGBoost::CAPI::RAW::XGDMatrixNumRow($dtrain, \$rows);
AI::XGBoost::CAPI::RAW::XGDMatrixNumCol($dtrain, \$cols);
say "Dimensions: $rows, $cols";

my $booster = 0;

AI::XGBoost::CAPI::RAW::XGBoosterCreate( [$dtrain] , 1, \$booster);

for my $iter (0 .. 10) {
    AI::XGBoost::CAPI::RAW::XGBoosterUpdateOneIter($booster, $iter, $dtrain);
}

my $out_len = 0;
my $out_result = 0;

AI::XGBoost::CAPI::RAW::XGBoosterPredict($booster, $dtest, 0, 0, \$out_len, \$out_result);
my $ffi = FFI::Platypus->new();
my $predictions = $ffi->cast(opaque => "float[$out_len]", $out_result);

#say join "\n", @$predictions;

AI::XGBoost::CAPI::RAW::XGBoosterFree($booster);
AI::XGBoost::CAPI::RAW::XGDMatrixFree($dtrain);
AI::XGBoost::CAPI::RAW::XGDMatrixFree($dtest);




