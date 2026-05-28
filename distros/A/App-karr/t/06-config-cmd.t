use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile LoadFile );

use App::karr::Config;
use App::karr::Cmd::Config;
use MockStore;

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

# Regression: `karr config show` crashed with
#   Can't locate object method "board_dir" via package "App::karr::Cmd::Config"
# because the command read its config from $self->board_dir->child('config.yml')
# instead of the ref-first store. These subtests drive the real command via a
# mock store so `show`/`get`/`set` no longer reference the dead board_dir method.
subtest 'config show runs through the command (no board_dir)' => sub {
  my $cmd = App::karr::Cmd::Config->new( store => MockStore->new );
  my $out;
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      open STDOUT, '>', \$out or die $!;
      $cmd->execute( ['show'], [] );
    };
    $@;
  };
  is $err, '', 'config show does not die on missing board_dir';
  like $out, qr/board\.name\s+Kanban Board/, 'shows default board name';
};

subtest 'config get runs through the command' => sub {
  my $cmd = App::karr::Cmd::Config->new( store => MockStore->new );
  my $out;
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      open STDOUT, '>', \$out or die $!;
      $cmd->execute( ['get', 'claim_timeout'], [] );
    };
    $@;
  };
  is $err, '', 'config get does not die';
  like $out, qr/1h/, 'returns the claim_timeout value';
};

subtest 'config set persists through the store (no board_dir)' => sub {
  my $store = MockStore->new;
  my $cmd   = App::karr::Cmd::Config->new( store => $store );
  my $out;
  my $err = do {
    local $@;
    eval {
      local *STDOUT; local *STDERR;
      open STDOUT, '>', \$out or die $!;
      open STDERR, '>', \my $junk or die $!;
      $cmd->execute( ['set', 'board.name', 'Hello World'], [] );
    };
    $@;
  };
  is $err, '', 'config set does not die on missing board_dir';
  is $store->saved_config->{board}{name}, 'Hello World',
    'set value persisted through store->save_config';
};

done_testing;
