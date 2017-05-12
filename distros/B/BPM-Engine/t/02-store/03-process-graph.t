use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::TestUtils;

use BPM::Engine;

my $engine = BPM::Engine->new( schema => schema() );
$engine->create_package('./t/var/08-samples.xpdl');
$engine->create_package('./t/var/02-branching.xpdl');

my ($process, $proc, $g) = ();
my $a = sub {
    my $id = shift;
    return $process->activities_rs({ activity_uid => $proc . '.' . $id })->first->id;
    };

$proc = 'wcp37';
$process = $engine->get_process_definition({ process_uid => $proc });
$g = $process->graph;
isa_ok($g, 'Graph');
ok($g->is_reachable(&$a('MC'), &$a('E')) );
ok(!$g->is_reachable(&$a('E'), &$a('MC')) );
ok(!$g->is_reachable(&$a('B'), &$a('E')) );
ok(!$g->is_transitive());

$proc = 'wcp38';
$process = $engine->get_process_definition({ process_uid => $proc });
$g = $process->graph;
ok($g->is_reachable(&$a('MC'), &$a('E')) );
ok(!$g->is_reachable(&$a('E'), &$a('MC')) );
ok(!$g->is_reachable(&$a('B'), &$a('E')) );
ok($g->is_reachable(&$a('C'), &$a('XOR')) );
ok($g->is_reachable(&$a('XOR'), &$a('C')) );
ok(!$g->is_transitive());

my $tcg = Graph::TransitiveClosure->new($g, path => 1);
my $u = &$a('MC');
my $v = &$a('SM');

is($tcg->is_reachable($u, $v),1);
is($tcg->is_transitive($u, $v),1);

done_testing;

