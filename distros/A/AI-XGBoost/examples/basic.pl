use 5.010;
use aliased 'AI::XGBoost::DMatrix';
use AI::XGBoost qw(train);

# We are going to solve a binary classification problem:
#  Mushroom poisonous or not

my $train_data = DMatrix->From(file => 'agaricus.txt.train');
my $test_data = DMatrix->From(file => 'agaricus.txt.test');

# With XGBoost we can solve this problem using 'gbtree' booster
#  and as loss function a logistic regression 'binary:logistic'
#  (Gradient Boosting Regression Tree)
# XGBoost Tree Booster has a lot of parameters that we can tune
# (https://github.com/dmlc/xgboost/blob/master/doc/parameter.md)

my $booster = train(data => $train_data, number_of_rounds => 10, params => {
        objective => 'binary:logistic',
        eta => 1.0,
        max_depth => 2,
        silent => 1
    });

# For binay classification predictions are probability confidence scores in [0, 1]
#  indicating that the label is positive (1 in the first column of agaricus.txt.test)
my $predictions = $booster->predict(data => $test_data);

say join "\n", @$predictions[0 .. 10];

