#!perl
# t/024-dag-merge.t: test Data::Hopen::G::DAG's warnings on _run()
use rlib 'lib';
use HopenTest;

use Data::Hopen qw(:default $QUIET);
use Data::Hopen::Scope::Hash;
use Data::Hopen::Scope::Environment;
use Data::Hopen::G::Link;

$Data::Hopen::VERBOSE = @ARGV;

run();
done_testing();

sub make_dag {  # See t/021-dag-single-goal.t for the explanation of this

    my $dag = hnew DAG => 'dag';
    my $goal = $dag->goal('all');
    is($goal->name, 'all', 'DAG::goal() sets goal name');
    ok($dag->_graph->has_edge($goal, $dag->_final), 'DAG::goal() adds goal->final edge');
    ok($dag->_graph->is_predecessorless_vertex($goal), 'Goal is predecessorless');

    # Make a first op
    my $op = hnew CollectOp => 'op1', levels => 3;
    isa_ok($op,'Data::Hopen::G::CollectOp');
    $dag->connect($op, $goal);

    # Make a second op
    $op = hnew OutputOp => 'op2', output => {foo => 1337};
    isa_ok($op,'Data::Hopen::G::OutputOp');
    $dag->connect($op, $goal);

    return $dag;
} #make_dag()

sub run {   # Run the tests
    my $dag = make_dag;
    my $outermost_scope = Data::Hopen::Scope::Hash->new()->put(
        foo => 42, bar => 'Bar'
    );

    my $hrOut = $dag->run(-context=>$outermost_scope);

    #diag Dumper $hrOut;
    is_deeply($hrOut, { all => {
                foo => [42, 1337],
                bar => 'Bar',
            } }, 'Outputs were merged OK');

    # TODO add tests for other merge strategies

} #run()
