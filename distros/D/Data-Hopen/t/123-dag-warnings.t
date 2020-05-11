#!perl
# t/123-dag-warnings.t: test Data::Hopen::G::DAG's warnings on _run()
use rlib 'lib';
use HopenTest;
use Test::Warn;

use Data::Hopen qw(:default *QUIET);
use Data::Hopen::Scope::Hash;
use Data::Hopen::Scope::Environment;
use Data::Hopen::G::Link;

$Data::Hopen::VERBOSE = @ARGV;

diag '"Last item in order isn\'t _final!" warnings are OK in this test.';
run();
done_testing();

sub make_dag {  # See t/121-dag-single-goal.t for the explanation of this

    my $dag = hnew DAG => 'dag';
    my $goal = $dag->goal('all');
    is($goal->name, 'all', 'DAG::goal() sets goal name');
    ok($dag->_graph->has_edge($goal, $dag->_final), 'DAG::goal() adds goal->final edge');
    ok($dag->_graph->is_predecessorless_vertex($goal), 'Goal is predecessorless');

    my $op = hnew CollectOp => 'op1', levels => 3;
    isa_ok($op,'Data::Hopen::G::CollectOp');
    $dag->_graph->add_vertex($op);
    ok($dag->_graph->is_isolated_vertex($op), 'Vertex is isolated');

    return $dag;
} #make_dag()

sub run {   # Run the tests
    my $dag = make_dag;
    my $outermost_scope = Data::Hopen::Scope::Hash->new()->put(foo => 42);

    warnings_exist { $dag->run($outermost_scope) }
        [qr/Node op1 is not connected/,
            qr/Goal all has no inputs/],
        'DAG run() provides expected warnings';

    $QUIET = true;      # can't use local
    warnings_are { $dag->run($outermost_scope) } [], 'With $QUIET, no warnings';
} #run()
