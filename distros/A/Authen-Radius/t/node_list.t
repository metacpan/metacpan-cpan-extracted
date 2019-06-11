use strict;
use warnings;
use Test::More tests => 10;
use Test::NoWarnings;

BEGIN { use_ok('Authen::Radius') };

my @nodes = ('127.0.0.1:1820', '127.0.0.2:1830');

my $auth = Authen::Radius->new(NodeList => \@nodes, Secret => 'secret', Debug => 0);
ok($auth, 'object created');
ok(!$auth->get_active_node, 'active node is not selected');

$auth = Authen::Radius->new(Host => '127.0.0.3:1840', NodeList => \@nodes, Secret => 'secret', Debug => 0);
ok($auth, 'object created');
ok(!$auth->get_active_node, 'Host must be from NodeList');

$auth = Authen::Radius->new(Host => '127.0.0.2:1830', NodeList => \@nodes, Secret => 'secret', Debug => 0);
ok($auth, 'object created');
is($auth->get_active_node, '127.0.0.2:1830', 'active node pre-set by Host option');

$auth = Authen::Radius->new(Host => 'aaa.radius', NodeList => \@nodes, Secret => 'secret', Debug => 0);
ok($auth, 'object created');
ok(!$auth->get_active_node, , 'unresolved Host ignored');
