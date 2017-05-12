use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 5;
use Test::Warn;
use App::clad;
use Clustericious::Admin;

create_config_ok 'Clad', {
  env => {},
  cluster => {
    cluster1 => [ qw( host1 host2 host3 ) ],
    cluster2 => [ qw( host4 host5 host6 ) ],
  },
  alias => {
    alias1 => 'foo bar baz',
    alias2 => [qw( foo bar baz )],
  },
};

subtest 'Clustericious::Admin->banners' => sub {
  plan tests => 2;
  warning_is {
    is_deeply [Clustericious::Admin->banners], [], 'returns empty list';
  } 'Class method call of Clustericious::Admin->banners is deprecated',
  'deprecation warning';
};

subtest 'Clustericious::Admin->clusters' => sub {
  plan tests => 2;
  warning_is {
    is_deeply
      [Clustericious::Admin->clusters],
      [qw( cluster1 cluster2 )],
      'returns correct values';
  } 'Class method call of Clustericious::Admin->clusters is deprecated',
  'deprecation warning';
};

subtest 'Clustericious::Admin->aliases' => sub {
  plan tests => 2;
  warning_is {
    is_deeply
      [Clustericious::Admin->aliases],
      [qw( alias1 alias2 )],
      'returns correct values';
  } 'Class method call of Clustericious::Admin->aliases is deprecated',
  'deprecation warning';
};

subtest 'Clustericious::Admin->run' => sub {
  my @new_args;
  
  do {
    no warnings;
    *App::clad::new = sub {
      shift;
      @new_args = @_;
      bless {}, 'App::clad'
    };
    *App::clad::run = sub { };
  };

  subtest 'no options' => sub {
    plan tests => 2;
    warning_is {
      Clustericious::Admin->run({}, 'cluster1', 'command');
    } 'Class method call of Clustericious::Admin->run is deprecated',
    'deprecation warning';
    is_deeply \@new_args, [qw( cluster1 command ) ], 'args match';
  };

  subtest '-n' => sub {
    plan tests => 2;
    warning_is {
      Clustericious::Admin->run({ n => 1 }, 'cluster1', 'command');
    } 'Class method call of Clustericious::Admin->run is deprecated',
    'deprecation warning';
    is_deeply \@new_args, [qw( -n cluster1 command ) ], 'args match';
  };

  subtest '-a' => sub {
    plan tests => 2;
    warning_is {
      Clustericious::Admin->run({ a => 1 }, 'cluster1', 'command');
    } 'Class method call of Clustericious::Admin->run is deprecated',
    'deprecation warning';
    is_deeply \@new_args, [qw( -a cluster1 command ) ], 'args match';
  };

  subtest '-l' => sub {
    plan tests => 2;
    warning_is {
      Clustericious::Admin->run({ l => 'foo' }, 'cluster1', 'command');
    } 'Class method call of Clustericious::Admin->run is deprecated',
    'deprecation warning';
    is_deeply \@new_args, [qw( -l foo cluster1 command ) ], 'args match';
  };
};
