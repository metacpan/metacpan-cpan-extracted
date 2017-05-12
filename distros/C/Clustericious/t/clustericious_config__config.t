use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 14;
use File::Temp qw( tempdir );
use Clustericious::Config;

create_config_ok common => <<'EOF1';
---
override_me: 9
url: <%= $url %>
daemon_prefork:
  listen: <%= $url %>
  pid: /tmp/<%= $app %>.pid
EOF1

create_config_ok special => <<'EOF2';
---
specialvalue: 123
override_me: 10
EOF2

create_config_ok Foo => <<'EOF3';
---
% extends_config 'common', url => 'http://localhost:9999', app => 'my_app';
% extends_config 'special';
override_me: 11
start_mode: daemon_prefork
daemon_prefork:
  lock: /tmp/my_app.lock
  maxspare: 2
  start: 2
EOF3

# Make another config file that references the first one,
# and also has a_remote_app, which has no config file.

my $c = Clustericious::Config->new('Foo');

#
# Some actual tests.
#
is $c->url, 'http://localhost:9999', 'url is ok';
is $c->{url}, 'http://localhost:9999', 'url is ok';
is $c->url, 'http://localhost:9999', 'url is ok (still)';
is $c->daemon_prefork->listen, $c->url, "extends_config plugin";
is $c->daemon_prefork->listen, "http://localhost:9999", "nested config var again";
my %h = $c->daemon_prefork;
my %i = ( 'listen' => 'http://localhost:9999',
           'pid' => '/tmp/my_app.pid',
           'lock' => '/tmp/my_app.lock',
           'maxspare' => 2,
           'start' => 2
         );
is_deeply \%h, \%i, "got as a hash";
is $c->specialvalue, 123, "read from another conf file";
is $c->override_me, 11, "override a config variable";

is ( (Clustericious::Config->new("SomeTestService")->flooble(default => "frog")), 'frog', 'set a default');
is ( (Clustericious::Config->new("SomeTestService")->flooble), 'frog', 'get a default');

pass 'forteenth';

