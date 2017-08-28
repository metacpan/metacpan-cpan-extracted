use aliased 'AI::XGBoost::DMatrix';
use AI::XGBoost qw(train);
use Data::Dataset::Classic::Iris;

# We are going to solve a multiple classification problem:
#  determining plant species using a set of flower's measures 

# XGBoost uses number for "class" so we are going to codify classes
my %class = (
    setosa => 0,
    versicolor => 1,
    virginica => 2
);

my $iris = Data::Dataset::Classic::Iris::get();

# Split train and test, label and features
my $train_dataset = [map {$iris->{$_}} grep {$_ ne 'species'} keys %$iris];
my $test_dataset = [map {$iris->{$_}} grep {$_ ne 'species'} keys %$iris];

sub transpose {
# Transposing without using PDL, Data::Table, Data::Frame or other modules
# to keep minimal dependencies
    my $array = shift;
    my @aux = ();
    for my $row (@$array) {
        for my $column (0 .. scalar @$row - 1) {
            push @{$aux[$column]}, $row->[$column];
        }
    }
    return \@aux;
}

$train_dataset = transpose($train_dataset);
$test_dataset = transpose($test_dataset);

my $train_label = [map {$class{$_}} @{$iris->{'species'}}];
my $test_label = [map {$class{$_}} @{$iris->{'species'}}];

my $train_data = DMatrix->From(matrix => $train_dataset, label => $train_label);
my $test_data = DMatrix->From(matrix => $test_dataset, label => $test_label);

# Multiclass problems need a diferent objective function and the number
#  of classes, in this case we are using 'multi:softprob' and
#  num_class => 3
my $booster = train(data => $train_data, number_of_rounds => 20, params => {
        max_depth => 3,
        eta => 0.3,
        silent => 1,
        objective => 'multi:softprob',
        num_class => 3
    });

my $predictions = $booster->predict(data => $test_data);



