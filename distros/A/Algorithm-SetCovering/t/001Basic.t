# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Algorithm::SetCovering') };

use Algorithm::SetCovering;

my $alg = Algorithm::SetCovering->new(
    columns => 4,
    mode    => "brute_force");

$alg->add_row(1, 0, 1, 0);
$alg->add_row(1, 1, 0, 0);
$alg->add_row(1, 1, 1, 0);
$alg->add_row(0, 1, 0, 1);
$alg->add_row(0, 0, 1, 1);

#########################
my @set = $alg->min_row_set(1, 1, 1, 1);
is("@set", "0 3", "Matching 1 1 1 1");

#########################
my @set = $alg->min_row_set(0, 0, 0, 0);
is("@set", "0", "Matching 0 0 0 0");

#########################
my @set = $alg->min_row_set(0, 0, 0, 1);
is("@set", "3", "Matching 0 0 0 1");

#########################
my @set = $alg->min_row_set(0, 0, 1, 1);
is("@set", "4", "Matching 0 0 1 1");

#########################
my @set = $alg->min_row_set(0, 1, 1, 1);
is("@set", "0 3", "Matching 0 1 1 1");
