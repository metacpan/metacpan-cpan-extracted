#!perl
# 100-h: test App::hopen::H
use rlib 'lib';
use HopenTest 'App::hopen::H';
use Path::Class;

use App::hopen::BuildSystemGlobals;
use Data::Hopen qw(:default :v);
use Data::Hopen::G::DAG;

package FakeGenerator {
    # Since AhG::FilesCmd requires a visitor be present
    use parent 'Data::Hopen::Visitor';
    use Class::Tiny;
    sub asset { }
    sub visit_node { }
    sub visit_goal { }
}

$VERBOSE = @ARGV;

# H requires $ProjDir to be initialized
$ProjDir = dir();
$DestDir = dir('nonexistent');

# Make the DAG
my $dag = hnew DAG => 'dag';
isa_ok($dag, 'Data::Hopen::G::DAG');

# Make the node
my $builder = $dag->App::hopen::H::files('foo.c');
isa_ok($builder, 'Data::Hopen::G::GraphBuilder');
isa_ok($builder->node, 'App::hopen::G::FilesCmd');
my $node = $builder->node;

# Run the DAG
$builder->default_goal;
my $dag_out = $dag->run(-visitor => FakeGenerator->new);

# Check the results
ok($node->outputs, 'Node has outputs');
is(ref $node->outputs->{made}, 'ARRAY', 'Node outputs made arrayref');
cmp_ok(@{$node->outputs->{made}}, '==', 1, 'One input->one output');
my $made = $node->outputs->{made}->[0];
isa_ok($made, 'App::hopen::Asset');
is($made->target->orig, dir()->file('foo.c'), 'Filename carries through');

done_testing();
