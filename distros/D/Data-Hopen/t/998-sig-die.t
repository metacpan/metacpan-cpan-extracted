#!perl
# 998-sig-die.t: test for coverage in Data::Hopen: what happens when a
# $SIG{'__DIE__'} handler
# elsewhere.
BEGIN {
    $SIG{'__DIE__'} = sub { die "oops" }
}

use rlib 'lib';
use HopenTest;

use Data::Hopen;
use Data::Hopen::G::DAG;
use Data::Hopen::Scope::Hash;

sub run {
    # Modified from t/021-dag-single-goal.t
    my $outermost_scope = Data::Hopen::Scope::Hash->new()->put(foo => 42);

    my $dag = hnew DAG => 'dag';

    my $goal = $dag->goal('all');
    ok($dag->_graph->has_edge($goal, $dag->_final), 'DAG::goal() adds goal->final edge');

    # Add an op
    my $op = hnew CollectOp => 'op1', levels => 3;
    $dag->connect($op, $goal);
    ok($dag->_graph->has_edge($op, $goal), 'DAG::connect() adds edge');

    # Oops - create cycle
    $dag->connect($goal, $op);
    ok($dag->_graph->has_edge($goal, $op), 'DAG::connect() adds other edge');

    # Run it
    eval { $dag->run($outermost_scope); };
    like $@, qr/oops/, "Didn't override SIG{'__DIE__'} handler";
} #run()

run();

done_testing();
