#!perl -T

use Test::More tests => 5;

use AI::CBR::Sim qw(sim_dist sim_frac sim_eq sim_set);
use AI::CBR::Case::Compound;
use AI::CBR::Retrieval;


my $case1 = AI::CBR::Case::Compound->new(
	# flight object
	{
		start  => { value => 'FRA', sim => \&sim_eq },
		target => { value => 'LIS', sim => \&sim_eq },
		price  => { value => 300,   sim => \&sim_dist, param => 200 },
	},
	# hotel object
	{
		stars => { value => 3,  sim => \&sim_dist, param => 2 },
		rate  => { value => 60, sim => \&sim_dist, param => 200 },		
	},
);

is(int @$case1, 2, '2 specs');


my @case_base = (
	{id=>1, start=>'FRA', target=>'DBV', price=>200, stars=>5, rate=>160}, # ~0.35
	{id=>2, start=>'FRA', target=>'LIS', price=>350, stars=>4, rate=>80},  # ~0.80
);

my $r = AI::CBR::Retrieval->new($case1, \@case_base);
$r->compute_sims();

is($r->{candidates}->[0]->{id}, 2, 'sim of id 2 is higher');
is($r->{candidates}->[1]->{id}, 1, 'sim of id 1 is lower');

is($case_base[0]->{_sim}, sqrt(0.5*0.25), 'sim of id 1 correct');
is($case_base[1]->{_sim}, sqrt((2.75/3)*(1.4/2)), 'sim of id 2 correct');

