#!perl
# t/021-dag-single-goal.t: basic tests of Data::Hopen::G::DAG with one goal
use rlib 'lib';
use HopenTest;
use Test::Deep;

use Data::Hopen;
use Data::Hopen::Scope::Hash;
use Data::Hopen::Scope::Environment;
use Data::Hopen::G::Link;

$Data::Hopen::VERBOSE = @ARGV;

sub run {
    my $outermost_scope = Data::Hopen::Scope::Hash->new()->add(foo => 42);

    my $dag = hnew DAG => 'dag';

    # Add a goal
    my $goal = $dag->goal('all');
    is($goal->name, 'all', 'DAG::goal() sets goal name');
    ok($dag->_graph->has_edge($goal, $dag->_final), 'DAG::goal() adds goal->final edge');

    # Add an op
    my $link = hnew Link => 'link1', greedy => 1;
    my $op = hnew CollectOp => 'op1', levels => 3;
        # levels = 0 => just the op's overrides
        # levels = 1 => also the op's inputs (DAG $node_inputs)
        # levels = 2 => also the DAG's overrides ($dag->scope)
        # levels = 3 => also the DAG's inputs (inputs to $dag->run)
        # TODO make a helper function for determining these?
    isa_ok($op,'Data::Hopen::G::CollectOp');
    $dag->connect($op, $link, $goal);
    ok($dag->_graph->has_edge($op, $goal), 'DAG::connect() adds edge');

    # Run it
    #print Dumper($outermost_scope);
    my $dag_out = $dag->run($outermost_scope);
    #print Dumper($dag_out);
    #print Dumper($op->outputs);

    cmp_deeply($dag_out, {all => { foo=>42 } }, "DAG passes everything through, tagged with the goal's name");
}

run();

done_testing();
