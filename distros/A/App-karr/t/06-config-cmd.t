use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile LoadFile );

use App::karr::Config;

subtest 'config set and get' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $file = path($dir)->child('config.yml');
  DumpFile($file->stringify, App::karr::Config->default_config);

  my $config = App::karr::Config->new(file => $file);
  is $config->data->{board}{name}, 'Kanban Board', 'default board name';

  # Simulate set
  $config->data->{board}{name} = 'My Board';
  $config->save;

  my $config2 = App::karr::Config->new(file => $file);
  is $config2->data->{board}{name}, 'My Board', 'name persisted';
};

subtest 'claim_timeout' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $file = path($dir)->child('config.yml');
  DumpFile($file->stringify, App::karr::Config->default_config);

  my $config = App::karr::Config->new(file => $file);
  is $config->claim_timeout, '1h', 'default timeout';

  $config->data->{claim_timeout} = '30m';
  $config->save;

  my $config2 = App::karr::Config->new(file => $file);
  is $config2->claim_timeout, '30m', 'timeout updated';
};

done_testing;
