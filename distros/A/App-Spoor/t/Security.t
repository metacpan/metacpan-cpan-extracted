use strict;
use warnings;
use utf8;
use v5.10;

use Test::More;
use App::Spoor::Security;

use Test::SetupTeardown;
use File::Path qw(remove_tree);
use File::Touch;

my $root_path = "/tmp/app_spoor_test_root";

sub setup {
  mkdir("$root_path", 0744);
  mkdir("$root_path/etc", 0755);
  mkdir("$root_path/var", 0755);
  mkdir("$root_path/var/lib", 0755);
}

sub teardown {
  remove_tree($root_path);
}

my $real_user_id = $<;

BEGIN {
  use_ok('App::Spoor::Security') || print "Could not load App::Spoor::Security\n";
}

my $environment = Test::SetupTeardown->new(setup => \&setup, teardown => \&teardown);

ok(
  defined(&App::Spoor::Security::check_config_directory),
  'App::Spoor::Security::check_config_directory is not defined'
);

$environment->run_test('Spoor config directory has correct permissions and ownership', sub {
    mkdir("$root_path/etc/spoor", 0700);
    ok(
      App::Spoor::Security::check_config_directory($real_user_id, $root_path),
      'Config directory has correct permissions and ownership'
    );
  });

$environment->run_test('Config directory has incorrect ownership',sub {
    mkdir("$root_path/etc/spoor", 0700);
    ok(
      !App::Spoor::Security::check_config_directory($real_user_id + 1, $root_path),
      'Config directory has incorrect ownership'
    );
  });

$environment->run_test('Config file has incorrect permissions',sub {
    mkdir("$root_path/etc/spoor", 0760);
    ok(
      !App::Spoor::Security::check_config_directory($real_user_id, $root_path),
      'Config directory has incorrect permissions'
    );
  });

ok(defined(&App::Spoor::Security::check_config_file), 'App::Spoor::Security::check_config_file is not defined');

$environment->run_test('Spoor config file has correct permissions and ownership', sub {
    mkdir("$root_path/etc/spoor", 0755);
    touch("$root_path/etc/spoor/spoor.yml");
    chmod(0600, "$root_path/etc/spoor/spoor.yml");
    ok(
      App::Spoor::Security::check_config_file($real_user_id, $root_path),
      'Config file has correct permissions and ownership'
    );
  });

$environment->run_test('Config file has incorrect ownership',sub {
    mkdir("$root_path/etc/spoor", 0755);
    touch("$root_path/etc/spoor/spoor.yml");
    chmod(0600, "$root_path/etc/spoor/spoor.yml");
    ok(
      !App::Spoor::Security::check_config_file($real_user_id + 1, $root_path),
      'Config file has incorrect ownership'
    );
  });

$environment->run_test('Config file has incorrect permissions',sub {
    mkdir("$root_path/etc/spoor", 0755);
    touch("$root_path/etc/spoor/spoor.yml");
    chmod(0500, "$root_path/etc/spoor/spoor.yml");
    ok(
      !App::Spoor::Security::check_config_file($real_user_id, $root_path),
      'Config file has incorrect permissions'
    );
  });

ok(
  defined(&App::Spoor::Security::check_persistence_directory),
  'App::Spoor::Security::check_persistence_directory is not defined'
);

$environment->run_test('Persistence directory has correct permissions and ownership', sub {
    mkdir("$root_path/var/lib/spoor", 0700);
    ok(
      App::Spoor::Security::check_persistence_directory($real_user_id, $root_path),
      'Persistence directory has correct permissions and ownership'
    );
  });

$environment->run_test('Persistence directory has incorrect ownership',sub {
    mkdir("$root_path/var/lib/spoor", 0700);
    ok(
      !App::Spoor::Security::check_persistence_directory($real_user_id + 1, $root_path),
      'Persistence directory has incorrect ownership'
    );
  });

$environment->run_test('Persistence directory has incorrect permissions',sub {
    mkdir("$root_path/var/lib/spoor", 0755);
    ok(
      !App::Spoor::Security::check_persistence_directory($real_user_id, $root_path),
      'Persistence directory has incorrect permissions'
    );
  });

ok(
  defined(&App::Spoor::Security::check_parsed_persistence_directory),
  'App::Spoor::Security::check_parsed_persistence_directory is not defined'
);

$environment->run_test('Parsed persistence directory has correct permissions and ownership', sub {
    mkdir("$root_path/var/lib/spoor", 0700);
    mkdir("$root_path/var/lib/spoor/parsed", 0700);
    ok(
      App::Spoor::Security::check_parsed_persistence_directory($real_user_id, $root_path),
      'Parsed persistence directory has correct permissions and ownership'
    );
  });

$environment->run_test('Parsed persistence directory has incorrect ownership',sub {
    mkdir("$root_path/var/lib/spoor", 0700);
    mkdir("$root_path/var/lib/spoor/parsed", 0700);
    ok(
      !App::Spoor::Security::check_parsed_persistence_directory($real_user_id + 1, $root_path),
      'Parsed persistence directory has incorrect ownership'
    );
  });

$environment->run_test('Parsed persistence directory has incorrect permissions',sub {
    mkdir("$root_path/var/lib/spoor", 0700);
    mkdir("$root_path/var/lib/spoor/parsed", 0755);
    ok(
      !App::Spoor::Security::check_parsed_persistence_directory($real_user_id, $root_path),
      'Parsed persistence directory has incorrect permissions'
    );
  });

ok(defined(&App::Spoor::Security::check_file), 'App::Spoor::Security::check_file is not defined');

$environment->run_test('File with correct ownership and permissions', sub {
    mkdir("$root_path/var/lib/spoor", 0700);
    mkdir("$root_path/var/lib/spoor/parsed", 0700);
    touch("$root_path/var/lib/spoor/parsed/foo");
    chmod(0600, "$root_path/var/lib/spoor/parsed/foo");
    ok(
      App::Spoor::Security::check_file("$root_path/var/lib/spoor/parsed/foo", $real_user_id, 0600),
      'File has correct permissions and ownership'
    );
  });

$environment->run_test('File with incorrect ownership', sub {
    mkdir("$root_path/var/lib/spoor", 0700);
    mkdir("$root_path/var/lib/spoor/parsed", 0700);
    touch("$root_path/var/lib/spoor/parsed/foo");
    chmod(0600, "$root_path/var/lib/spoor/parsed/foo");
    ok(
      !App::Spoor::Security::check_file("$root_path/var/lib/spoor/parsed/foo", $real_user_id + 1, 0600),
      'File has incorrect ownership'
    );
  });

$environment->run_test('File with incorrect permissions', sub {
    mkdir("$root_path/var/lib/spoor", 0700);
    mkdir("$root_path/var/lib/spoor/parsed", 0700);
    touch("$root_path/var/lib/spoor/parsed/foo");
    chmod(0600, "$root_path/var/lib/spoor/parsed/foo");
    ok(
      !App::Spoor::Security::check_file("$root_path/var/lib/spoor/parsed/foo", $real_user_id, 0500),
      'File has incorrect permissions'
    );
  });

done_testing();
