use Test::More;

use lib qw(t/lib);

use Schema;
my $schema = Schema->connect;
my $rs = $schema->resultset('SubClassI');

my @status = qw(foo bar);


ok($rs->create({id => 1, status => 1}));
  
is($rs->find(1)->foo, 1);

done_testing;