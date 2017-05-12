use Test::More;

use lib qw(t/lib);

use TestLib;

my $t = new TestLib;

my $schema = $t->get_schema;
my $rs = $schema->resultset("Complex");

ok($rs->is_directed, 'resultset has Graph methods');

done_testing;