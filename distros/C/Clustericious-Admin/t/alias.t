use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 8;
use App::clad;
use YAML::XS qw( Dump );
use Capture::Tiny qw( capture );

create_config_ok Clad1 => {
  env => {},
  cluster => {
    cluster1 => [ qw( host1 host2 host3 ) ],
    cluster2 => [ qw( host4 host5 host6 ) ],
  },
};

subtest default => sub {
  plan tests => 1;
  my $clad = App::clad->new('--config' => 'Clad1', 'cluster1' => 'uptime');
  my %alias = $clad->alias;
  is_deeply \%alias, {}, 'no aliases';
};

create_config_ok Clad => {
  env => {},
  cluster => {
    cluster1 => [ qw( host1 host2 host3 ) ],
    cluster2 => [ qw( host4 host5 host6 ) ],
  },
  alias => {
    foo => 'my foo alias',
    bar => [ qw( my bar alias ) ],
  },
};

subtest 'with alias' => sub {
  plan tests => 1;
  my $clad = App::clad->new('cluster1' => 'uptime');
  my %alias = $clad->alias;
  is_deeply \%alias, { foo => 'my foo alias', bar => [ qw( my bar alias ) ] }, 'no aliases';
};

subtest 'with alias unused' => sub {
  plan tests => 1;
  my $clad = App::clad->new('cluster1' => 'one', 'two', 'three');
  is_deeply $clad->command, [ qw( one two three ) ], 'command = one two three';
};

subtest 'with alias used scalar' => sub {
  plan tests => 1;
  my $clad = App::clad->new('cluster1' => 'foo', 'two', 'three');
  is_deeply $clad->command, [ 'my foo alias', qw( two three ) ], 'command = my foo alias two three';
};

subtest 'with alias used list ref' => sub {
  plan tests => 1;
  my $clad = App::clad->new('cluster1' => 'bar', 'two', 'three');
  is_deeply $clad->command, [ qw( my bar alias two three ) ], 'command = my bar alias two three';
};

create_config_ok Clad2 => {
  env => {},
  cluster => {
    cluster1 => [ qw( host1 host2 host3 ) ],
    cluster2 => [ qw( host4 host5 host6 ) ],
  },
  aliases => {
    foo => 'my foo alias',
    bar => [ qw( my bar alias ) ],
  },
};
