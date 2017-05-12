BEGIN {
    $ENV{MYAPP_DB_1_USER} = 'admin';
    $ENV{MYAPP_DB_1_PASS} = 's3cret';
}

use utf8;
use strict;
use warnings;
use Test::More;
use Config::Environment;

my $conf = Config::Environment->new('myapp');
my $conn = $conf->param('db.1.conn' => 'dbi:mysql:dbname=foobar');
my $user = $conf->param('db.1.user');
my $pass = $conf->param('db.1.pass');

ok $conf, '$conf is ok';
is $conn, 'dbi:mysql:dbname=foobar', '$conn is ok';
is $user, 'admin', '$user is ok';
is $pass, 's3cret', '$pass is ok';

my $info = $conf->param('db.1');
is $info->{conn}, 'dbi:mysql:dbname=foobar', '$info->{conn} is ok';
is $info->{user}, 'admin', '$info->{user} is ok';
is $info->{pass} , 's3cret', '$info->{pass} is ok';

my $db1 = { 1 => { conn => $conn, user => $user, pass => $pass } };
is_deeply $conf->param('db'), $db1, '$db1 is ok (deep cmp)';

my $srvs = $conf->param('server' => {node => ['10.10.10.02', '10.10.10.03']});
is_deeply $conf->param('server'), $srvs, '$srvs is ok (deep cmp)';

ok exists $ENV{MYAPP_SERVER_NODE_1}, '$ENV{MYAPP_SERVER_NODE_1} exists';
ok exists $ENV{MYAPP_SERVER_NODE_2}, '$ENV{MYAPP_SERVER_NODE_2} exists';
is $ENV{MYAPP_SERVER_NODE_1}, '10.10.10.02', '$ENV{MYAPP_SERVER_NODE_1} is ok';
is $ENV{MYAPP_SERVER_NODE_2}, '10.10.10.03', '$ENV{MYAPP_SERVER_NODE_2} is ok';

ok ref $conf->param('server'), 'server params returns ref';
ok ref $conf->param('server.node'), 'server.node params returns ref';
ok ! ref $conf->param('server.node.1'), 'server.node.1 params returns non-ref';
ok ! ref $conf->param('server.node.2'), 'server.node.2 params returns non-ref';
is $conf->param('server.node.1'), '10.10.10.02', 'server.node.1 is ok';
is $conf->param('server.node.2'), '10.10.10.03', 'server.node.2 is ok';

my ($node1, $node2) = $conf->params(qw(server.node.1 server.node.2));
is $node1, '10.10.10.02', '$node1 is ok (returned from list)';
is $node2, '10.10.10.03', '$node2 is ok (returned from list)';

my $env = $conf->environment;
is 5, keys %$env, '$env has 5 keys';

my @keys = qw(
    MYAPP_DB_1_CONN
    MYAPP_DB_1_USER
    MYAPP_DB_1_PASS
    MYAPP_SERVER_NODE_1
    MYAPP_SERVER_NODE_2
);
for my $key (@keys) {
    ok exists $ENV{$key}, "\$ENV{$key} exists";
    ok exists $env->{$key}, "\$env{$key} exists";
    is $env->{$key}, $ENV{$key}, "\$env{$key} eq \$ENV{$key} (cmp)";
}

done_testing;
