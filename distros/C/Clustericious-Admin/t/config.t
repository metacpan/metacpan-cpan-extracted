use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 2;
use App::clad;
use Capture::Tiny qw( capture );

unshift @INC, sub {
  my(undef, $filename) = @_;
  die "do not use ConfigData.pm" if $filename eq 'Clustericious/Admin/ConfigData.pm';
  return;
};

subtest defaults => sub {
  plan tests => 6;

  create_config_ok 'Clad', {
    env => {},
    cluster => {
      cluster1 => [ qw( host1 host2 host3 ) ],
      cluster2 => [ qw( host4 host5 host6 ) ],
    },
  };

  my $clad = App::clad->new('cluster1', 'echo');

  isa_ok $clad->config, 'Clustericious::Config';
  is($clad->server_command, 'clad --server', 'clad.server_command');
  is($clad->ssh_command, 'ssh', 'clad.ssh_command');
  isa_ok($clad->ssh_options, 'ARRAY', 'clad.ssh_options');
  is_deeply([$clad->ssh_extra], [], 'clad.ssh_extra');
  
};

subtest overrides => sub {
  plan tests => 6;

  create_config_ok 'Clad1', {
    env => {},
    cluster => {
      cluster1 => [ qw( host1 host2 host3 ) ],
      cluster2 => [ qw( host4 host5 host6 ) ],
    },
    
    server_command => 'my server command',
    ssh_command => 'xssh',
    ssh_options => [ -o => 'Foo=no', -o 'Bar=>yes' ],
    ssh_extra   => [ -o => 'LogLevel=ERROR' ],
  };

  my $clad = App::clad->new('--config' => 'Clad1', 'cluster1', 'echo');

  isa_ok $clad->config, 'Clustericious::Config';
  is($clad->server_command, 'my server command', 'clad.server_command');
  is($clad->ssh_command, 'xssh', 'clad.ssh_command');
  is_deeply([$clad->ssh_options], [-o => 'Foo=no', -o 'Bar=>yes' ], 'clad.ssh_options');
  is_deeply([$clad->ssh_extra], [ -o => 'LogLevel=ERROR' ], 'clad.ssh_extra');
};
