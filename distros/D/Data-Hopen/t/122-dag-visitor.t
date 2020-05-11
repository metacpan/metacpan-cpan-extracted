#!perl
# t/122-dag-visitor.t: test Data::Hopen::G::DAG's invoking of a visitor
use rlib 'lib';
use HopenTest;
use Test::Deep;

plan tests => 9;

use Data::Hopen;
use Data::Hopen::Scope::Hash;
use Data::Hopen::Scope::Environment;
use Data::Hopen::G::Link;

$Data::Hopen::VERBOSE = @ARGV;

run();

sub make_dag {  # See t/121-dag-single-goal.t for the explanation of this

    my $dag = hnew DAG => 'dag';
    my $goal = $dag->goal('all');
    is($goal->name, 'all', 'DAG::goal() sets goal name');
    ok($dag->_graph->has_edge($goal, $dag->_final), 'DAG::goal() adds goal->final edge');

    my $link = hnew Link => 'link1', greedy => 1;
    my $op = hnew CollectOp => 'op1', levels => 3;
    isa_ok($op,'Data::Hopen::G::CollectOp');
    $dag->connect($op, $link, $goal);
    ok($dag->_graph->has_edge($op, $goal), 'DAG::connect() adds edge');

    return $dag;
}

{ # A simple visitor
    package MyVisitor;
    use Class::Tiny { node=>undef, goal=>undef };
    use Test::More;
    sub visit_goal {
        my ($self, $goal) = @_;
        $self->goal($goal);
    }
    sub visit_node {
        my ($self, $node) = @_;
        $self->node($node);
    }
}

sub run {   # Run the tests
    my $dag = make_dag;
    my $visitor = MyVisitor->new;
    my $outermost_scope = Data::Hopen::Scope::Hash->new()->put(foo => 42);

    my $dag_out = $dag->run($outermost_scope, -visitor => $visitor);
    ok(defined $visitor->node, 'Visited node');
    ok(defined $visitor->goal, 'Visited goal');
    is($visitor->node->name, 'op1', 'Got the node');
    is($visitor->goal->name, 'all', 'Got the goal');

    cmp_deeply($dag_out, {all => { foo=>42 } }, "DAG passes everything through, tagged with the goal's name");
}
