#!perl -T

use Test::More tests => 2;

use AI::CBR::Sim qw(sim_dist sim_frac sim_eq sim_set);
use AI::CBR::Case;


my $case1 = AI::CBR::Case->new(
	age      => { value => 30,             sim => \&sim_amount },
	gender   => { value => 'male',         sim => \&sim_eq     },
	job      => { value => 'programmer',   sim => \&sim_eq     },
	symptoms => { value => [qw(headache)], sim => \&sim_set,   weight =>2 },
);

my $weights_at_1 = int grep { $case1->{$_}->{weight} == 1 } keys %$case1;
my $weights_at_2 = int grep { $case1->{$_}->{weight} == 2 } keys %$case1;
is($weights_at_1, 3, 'default weights set to 1');
is($weights_at_2, 1, 'symptom weight set to 2');

