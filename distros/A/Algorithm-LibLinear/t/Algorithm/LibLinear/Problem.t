use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Algorithm::LibLinear' }

my @labels = (1, 2, 1, 2, 3);
my @features = (
    +{ 2 => 0.1, 3 => 0.2, },
    +{ 2 => 0.1, 3 => 0.3, 4 => -1.2, },
    +{ 1 => 0.4, },
    +{ 1 => 0.1, 4 => 1.4, 5 => 0.5, },
    +{ 1 => -0.1, 2 => -0.2, 3 => 0.1, 4 => 1.1, 5 => 0.1, },
);

my $problem =
    new_ok 'Algorithm::LibLinear::Problem' => [\@labels, \@features, 1];

is $problem->bias, 1;
is $problem->data_set_size, 5;
is $problem->num_features, 6;

done_testing;
