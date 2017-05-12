use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Log;
use Test::More tests => 3;
use Clustericious::Config;

foreach my $name (qw( Foo Bar Flag ))
{
  subtest Foo => sub {
    plan tests => 4;
    create_config_ok $name;
    my $config = Clustericious::Config->new($name);
    isa_ok $config, 'Clustericious::Config';
    is $config->test1, 1, 'test1 = 1';
    is $config->test2, 1, 'test2 = 1';
  };
}

__DATA__

@@ etc/Foo.conf
---
test1: 1
% our $bar;
% $bar++;
test2: <%= $bar %>


@@ etc/Bar.conf
---
test1: 1
% our $bar;
% $bar++;
test2: <%= $bar %>


@@ etc/Flag.conf
---
<%= extends_config 'Bar' %>


