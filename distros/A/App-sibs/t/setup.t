use strict;
use Test::More;
use File::Path qw( remove_tree );

plan skip_all => 'Cannot read bin/sibs' unless -x 'bin/sibs';

$ENV{HOME} = 't/home';
my $script = do 'bin/sibs';

{
  $script->{silent} = !$ENV{HARNESS_IS_VERBOSE};
  $script->{config} = 't/config.sibs';
  remove_tree 't/home/.ssh' if -d 't/home/.ssh';
  unlink $script->{config} if -r $script->{config};
}

{
  ok $script, 'enable to load bin/sibs' or diag $@;
  is $script->ssh_file('config'), 't/home/.ssh/config', 'got ssh_file(config)';
}

{
  my @read = (
    'test@dummy.com',
    '.swp backup Downloads',
    './t',
    'rsync://bruce@localhost/tmp',
  );

  no warnings 'redefine';
  local *main::_read = sub { $_ = shift @read };

  $script->create_sibs_config;
  $script->load_config;
  is_deeply(
    $script,
    {
      config => 't/config.sibs',
      silent => !$ENV{HARNESS_IS_VERBOSE},
      ssh_dir => 't/home/.ssh',
      email => 'test@dummy.com',
      exclude => [qw( .swp backup Downloads )],
      source => [qw( ./t )],
      destination => 'rsync://bruce@localhost/tmp',
    },
    'config was created',
  );
}

{
  $script->add_backup_host_to_ssh_config;
  open my $CONFIG, '<', 't/home/.ssh/config';
  my @config = (
    "",
    "Host sibs-localhost",
    "  Hostname localhost",
    "  IdentityFile t/home/.ssh/sibs_dsa",
  );

  while(<$CONFIG>) {
    my $line = shift @config;
    is $_, "$line\n", "config has $line";
  }

  $script->add_backup_host_to_ssh_config;
  is -s 't/home/.ssh/config', 78, 'config is the same size';
}

done_testing;
