#!perl -T

use Test::More tests => 7;

use AI::CBR::Sim qw(sim_frac sim_eq sim_set);
use AI::CBR::Case;
use AI::CBR::Retrieval;


my $case_base = [
	{id=>1, age=>25, gender=>'male',   job=>'manager',    symptoms=>[qw(headache)],       reason=>'stress' },
	{id=>2, age=>40, gender=>'male',   job=>'programmer', symptoms=>[qw(headache cough)], reason=>'flu'    },
	{id=>3, age=>30, gender=>'female', job=>'programmer', symptoms=>[qw(cough)],          reason=>'flu'    },
	{id=>4, age=>25, gender=>'male',   job=>'programmer', symptoms=>[qw(headache)],       reason=>'alcohol'},
];

my $case1 = AI::CBR::Case->new(
	age      => { value => 30,             sim => \&sim_frac },
	gender   => { value => 'male',         sim => \&sim_eq   },
	job      => { value => 'programmer',   sim => \&sim_eq   },
	symptoms => { value => [qw(headache)], sim => \&sim_set,   weight =>2 },
);


my $retrieval = AI::CBR::Retrieval->new($case1, $case_base);

$retrieval->compute_sims();

# check similarities
is($case_base->[0]->{_sim}, (5/6+1+0+2*1/1)/5, 'sim 1 correct'); # ~0.77
is($case_base->[1]->{_sim}, (3/4+1+1+2*1/2)/5, 'sim 2 correct'); # 0.75
is($case_base->[2]->{_sim}, (1/1+0+1+2*0/2)/5, 'sim 3 correct'); # 0.4
is($case_base->[3]->{_sim}, (5/6+1+1+2*1/1)/5, 'sim 4 correct'); # ~0.97


# check retrieval
is($retrieval->most_similar_candidate->{id}, 4, 'most similar candidate returned');
is($retrieval->n_most_similar_candidates(3), 3, 'n most similar candidates returned');
is($retrieval->first_confirmed_candidate('reason')->{id}, 2, 'first confirmed reason candidate returned');

