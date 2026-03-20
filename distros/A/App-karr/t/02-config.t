use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile );

use App::karr::Config;

subtest 'default config' => sub {
  my $config = App::karr::Config->default_config(name => 'Test Board');
  is $config->{board}{name}, 'Test Board';
  is $config->{next_id}, 1;
  ok scalar @{$config->{statuses}}, 'has statuses';
  ok scalar @{$config->{priorities}}, 'has priorities';
};

subtest 'statuses parsing' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $file = path($dir)->child('config.yml');
  DumpFile($file->stringify, App::karr::Config->default_config);

  my $config = App::karr::Config->new(file => $file);
  my @statuses = $config->statuses;
  ok scalar @statuses >= 5, 'at least 5 statuses';
  is $statuses[0], 'backlog';
  is $statuses[2], 'in-progress';
};

subtest 'next_id increments' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $file = path($dir)->child('config.yml');
  DumpFile($file->stringify, App::karr::Config->default_config);

  my $config = App::karr::Config->new(file => $file);
  is $config->next_id, 1;

  # Reload to check persistence
  my $config2 = App::karr::Config->new(file => $file);
  is $config2->next_id, 2;
};

subtest 'wip_limit' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $file = path($dir)->child('config.yml');
  DumpFile($file->stringify, App::karr::Config->default_config);

  my $config = App::karr::Config->new(file => $file);
  is $config->wip_limit('in-progress'), 3;
  is $config->wip_limit('review'), 2;
  ok !defined $config->wip_limit('backlog');
};

done_testing;
