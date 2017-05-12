use strict;
use warnings;
use File::Basename;
use File::Spec;
use Test::Deep;
use Test::More;

use_ok 'Algorithm::LibLinear::Model';

my $tolerance = 10e-15;

my $model_file = File::Spec->catfile(dirname(__FILE__), 'classifier.model');
my $classifier = Algorithm::LibLinear::Model->load(filename => $model_file);

cmp_deeply(
    $classifier,
    all(
        isa('Algorithm::LibLinear::Model'),
        methods(
            class_labels => [1 .. 3],
            is_probability_model => bool(0),
            is_regression_model => bool(0),
            num_classes => 3,
            num_features => 4,
        ),
    ),
);

my @biases = map { $classifier->bias($_) } 1 .. $classifier->num_classes;
cmp_deeply(
    \@biases,
    [ map {
        num($_, $tolerance);
    } (-0.517607618406239, -0.546185221735258, -3.08979444883496) ],
);

my @coefficients = map {
    my $feature_index = $_;
    [ map {
        $classifier->coefficient($feature_index, $_);
    } 1 .. $classifier->num_classes ];
} 1 .. $classifier->num_features;
cmp_deeply(
    \@coefficients,
    [
        map {
            [ map { num($_, $tolerance) } @$_ ];
        } (
            [ 0.04103487079450262, -0.008771914659137776, -0.1160503346528812 ],
            [ 0.2342191077303725, -0.1250698131581897, -0.1190538111847415 ],
            [ -0.2048151760378588, 0.1373834860433695, 0.5354628806913007 ],
            [ -0.1991378710551831, -0.1214875508849184, 0.3862178521798377 ],
        ),
    ],
);

done_testing;
