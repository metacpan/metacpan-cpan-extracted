use Test::More;

use lib qw(t/lib);

use TestLib;

my $t = new TestLib;

my $schema = $t->get_schema;
my $rs = $schema->resultset("Complex")->search(undef, { order_by => 'id_foo' });

$rs->graph;

is($rs->first->successors, 3, 'result has Graph methods');


done_testing;