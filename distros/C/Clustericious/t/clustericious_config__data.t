use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 4;
use Clustericious::Config;

create_config_ok 'Foo';

my $config = Clustericious::Config->new('Foo');
isa_ok $config, 'Clustericious::Config';
is $config->a, 1, 'config.a = 1';
is $config->b, 2, 'config.a = 2';

__DATA__

@@ etc/Foo.conf
---
a: 1
b: 2
