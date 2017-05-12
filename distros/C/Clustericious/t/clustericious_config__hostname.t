use strict;
use warnings;
eval q{ use Test::Clustericious::Log };
use Test::Clustericious::Config;
use Test::More tests => 3;
use Sys::Hostname ();
use Clustericious::Config;

my $hostname = sub {
  'froodle.fragmire.example.com';
};

do { no warnings 'redefine'; *Sys::Hostname::hostname = $hostname };

create_config_ok Foo => <<EOF;
---
host1: <%= hostname %>
host2: <%= hostname_full %>
EOF

my $config = eval { Clustericious::Config->new('Foo') };
diag $@ if $@;

is eval { $config->host1 }, 'froodle', 'config.host1 = froodle';
diag $@ if $@;
is eval { $config->host2 }, 'froodle.fragmire.example.com', 'config.host2 = froodle.fragmire.example.com';
