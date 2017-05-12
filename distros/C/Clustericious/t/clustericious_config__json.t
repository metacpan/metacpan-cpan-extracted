use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Log;
use Test::More tests => 14;
use Clustericious::Config;

create_config_ok Foo => <<EOF;
---
x: 1
y: <%= json [0..11] %>
EOF

my $config = eval { Clustericious::Config->new('Foo') };
diag $@ if $@;

is $config->x, 1, 'config.x = 1';

for(0..11)
{
  is eval { $config->y->[$_] }, $_, "config.y.$_ = $_";
  diag $@ if $@;
}
