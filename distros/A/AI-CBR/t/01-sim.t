#!perl -T

use Test::More tests => 22;

use AI::CBR::Sim qw(sim_dist sim_frac sim_eq sim_set);


# sim_dist
is(sim_dist(26,22,10), 0.6, 'sim_dist works');
is(sim_dist(-1,-0.9,0.5), 0.8, 'sim_dist works');
is(sim_dist(0,4,8), 0.5, 'sim_dist works');

# sim_frac
is(sim_frac(0,0), 1, 'sim_frac works');
is(sim_frac(0,2), 0, 'sim_frac works');
is(sim_frac(4,0), 0, 'sim_frac works');
is(sim_frac(2,4), 0.5, 'sim_frac works');
is(sim_frac(16,4), 0.25, 'sim_frac works');
is(sim_frac(100,40), 0.4, 'sim_frac works');

# sim_eq
is(sim_eq('a','b'), 0, 'sim_eq works');
is(sim_eq('','b'), 0, 'sim_eq works');
is(sim_eq('a',''), 0, 'sim_eq works');
is(sim_eq('a','a'), 1, 'sim_eq works');

# sim_set
is(sim_set([], []), 1, 'sim_set works');
is(sim_set([qw(a b c)], []), 0, 'sim_set works');
is(sim_set([], [qw(d e f)]), 0, 'sim_set works');
is(sim_set([qw(a b)], [qw(c d)]), 0, 'sim_set works');
is(sim_set([qw(a b)], [qw(b c)]), 1/3, 'sim_set works');
is(sim_set([qw(a b c)], [qw(b c d)]), 0.5, 'sim_set works');
is(sim_set([qw(a b c d)], [qw(d e f g)]), 1/7, 'sim_set works');
is(sim_set([qw(a b c d)], [qw(a b c)]), 0.75, 'sim_set works');
is(sim_set([qw(a b c d)], [qw(a b c d)]), 1, 'sim_set works');

