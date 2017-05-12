use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Log;
use Test::More tests => 3;
use Clustericious::Config;

create_config_ok 'Foo::Bar::Baz' => {
  x => 1,
  y => 2,
};

my $config = eval { Clustericious::Config->new('Foo::Bar::Baz') };
diag $@ if $@;

is eval { $config->x }, 1, "config.x = 1";
diag $@ if $@;
is eval { $config->y }, 2, "config.y = 2";
diag $@ if $@;
