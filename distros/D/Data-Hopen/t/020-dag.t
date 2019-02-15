#!perl
# 020-dag.t: basic tests of Data::Hopen::G::DAG
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Data::Hopen::G::DAG';
    diag "Testing Data::Hopen::G::DAG from $INC{'Data/Hopen/G/DAG.pm'}";
}

my $dag = Data::Hopen::G::DAG->new(name=>'foo');
isa_ok($dag, 'Data::Hopen::G::DAG');
is($dag->name, 'foo', 'Name was set by constructor');
$dag->name('bar');
is($dag->name, 'bar', 'Name was set by accessor');

ok($dag->_graph, 'DAG has a _graph');
ok($dag->_final, 'DAG has a _final');

my @goals;
foreach my $goalname (qw(all clean)) {
    my $g1 = $dag->goal($goalname);
    push @goals, $g1;
    isa_ok($g1, 'Data::Hopen::G::Goal', 'DAG::goal()');
    is($g1->name, $goalname, 'DAG::goal() sets goal name');
    ok($dag->_graph->has_edge($g1, $dag->_final), 'DAG::goal() adds goal->final edge');
}

ok($dag->default_goal, 'DAG::goal() sets default_goal');
is($dag->default_goal->name, 'all', 'First call to DAG::goal() sets default goal name');

done_testing();
