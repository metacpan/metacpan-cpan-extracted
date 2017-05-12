use Test::More;
use Test::Memory::Cycle;

use lib qw(t/lib);

use TestLib;

my $t = new TestLib;

my $schema = $t->get_schema;

my $g = $schema->resultset("Complex");
$g->graph;

memory_cycle_ok( $g );

my @vertices = $g->all;

memory_cycle_ok( $_ ) for(@vertices);

done_testing;