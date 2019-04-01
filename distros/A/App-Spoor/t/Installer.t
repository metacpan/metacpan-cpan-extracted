use strict;
use warnings;
use v5.10;

use Test::More;
use Test::SetupTeardown;

use File::Path qw(remove_tree);
use Path::Tiny qw(path);
use YAML::Tiny;

use App::Spoor::Config;
use App::Spoor::LoginUnitFile;
use App::Spoor::AccessUnitFile;

my $test_user = getpwuid($>);

sub setup {
  mkdir('/tmp/app_spoor_test_root', 0744);
  mkdir('/tmp/app_spoor_test_root/etc', 0744);
  mkdir('/tmp/app_spoor_test_root/etc/systemd', 0744);
  mkdir('/tmp/app_spoor_test_root/etc/systemd/system', 0744);
  mkdir('/tmp/app_spoor_test_root/var', 0744);
  mkdir('/tmp/app_spoor_test_root/var/lib', 0744);
  mkdir('/tmp/app_spoor_test_root/var/cpanel', 0744);
}

sub teardown {
  remove_tree('/tmp/app_spoor_test_root');
}

BEGIN {
  use_ok('App::Spoor::Installer') || print "Could not load App::Spoor::Installer\n";
}

ok (defined(&App::Spoor::Installer::install), 'App::Spoor::Installer is defined');

# Setup test directory tBuil
my %installation_config =(
  login_log_path => '/var/log/login',
  access_log_path => '/var/log/access',
  error_log_path => '/var/log/error',
  api_identifier => 'ABC123',
  api_secret => 'secret456'
);
my $root_path = '/tmp/app_spoor_test_root';
my $config_file_directory = '/tmp/app_spoor_test_root/etc/spoor';
my $config_file_path = "$config_file_directory/spoor.yml";
my $spoor_state_directory = "$root_path/var/lib/spoor";
my $spoor_parsed_state_directory = "$root_path/var/lib/spoor/parsed";
my $spoor_transmitted_state_directory = "$root_path/var/lib/spoor/transmitted";
my $spoor_transmission_failed_state_directory = "$root_path/var/lib/spoor/transmission_failed";
my $cpanel_perl_dir = "$root_path/var/cpanel/perl5/lib";

my $login_follower_unit_file = "$root_path/etc/systemd/system/spoor-login-follower.service";
my $access_follower_unit_file = "$root_path/etc/systemd/system/spoor-access-follower.service";
my $error_follower_unit_file = "$root_path/etc/systemd/system/spoor-error-follower.service";
my $transmitter_unit_file = "$root_path/etc/systemd/system/spoor-transmitter.service";

my $cpanel_hook_file_path = "$root_path/var/cpanel/perl5/lib/SpoorForwardHook.pm";

my $environment = Test::SetupTeardown->new(setup => \&setup, teardown => \&teardown);

$environment->run_test('creates config file', sub {
    App::Spoor::Installer::install(\%installation_config, $root_path);
    ok(-d $config_file_directory, 'Spoor config directory created');
    ok(-o $config_file_directory, 'Spoor config directory owned by effective user');
    is((stat($config_file_directory))[2] & 07777, 0700, 'Spoor config directory has correct permissions');
    ok(-f $config_file_path, 'Spoor config file created');
    is((stat($config_file_path))[2] & 07777, 0600, 'Spoor config file has correct permissions');
  });

my %expected_config = (
  followers => {
    login => {
      name => $installation_config{'login_log_path'},
      maxinterval => 10,
      debug => 1,
      transformer => 'bin/login_log_transformer.pl',
    },
    access => {
      name => $installation_config{'access_log_path'},
      maxinterval => 10,
      debug => 1,
      transformer => 'bin/login_log_transformer.pl',
    },
    error => {
      name => $installation_config{'error_log_path'},
      maxinterval => 10,
      debug => 1,
      transformer => 'bin/login_log_transformer.pl',
    },
  },
  transmission => {
    credentials => {
      api_identifier => $installation_config{'api_identifier'},
      api_secret => $installation_config{'api_secret'},
    },
    host => 'https://spoor.capefox.co',
    endpoints => {
      report => '/api/reports',
    }
  }
);

$environment->run_test('populates config file', sub {
    App::Spoor::Installer::install(\%installation_config, $root_path);
    my $config_file = YAML::Tiny->read($config_file_path);
    my %actual_config = %{ $config_file->[0] };
    is_deeply(\%actual_config, \%expected_config, 'Configs match');
  });

$environment->run_test('creates directory structure for storing state', sub {
    App::Spoor::Installer::install(\%installation_config, $root_path);
    ok(-d $spoor_state_directory, 'Spoor state directory created');
    ok(-o $spoor_state_directory, 'Spoor state directory owned by effective user');
    is((stat($spoor_state_directory))[2] & 07777, 0700, 'Spoor state directory has correct permissions');

    ok(-d $spoor_parsed_state_directory, 'Spoor parsed state directory created');
    ok(-o $spoor_parsed_state_directory, 'Spoor parsed state directory owned by effective user');
    is((stat($spoor_parsed_state_directory))[2] & 07777, 0700, 'Spoor parsed state directory has correct permissions');

    ok(-d $spoor_transmitted_state_directory, 'Spoor transmitted state directory created');
    ok(-o $spoor_transmitted_state_directory, 'Spoor transmitted state directory owned by effective user');
    is(
      (stat($spoor_transmitted_state_directory))[2] & 07777,
      0700,
      'Spoor transmitted state directory has correct permissions'
    );

    ok(-d $spoor_transmission_failed_state_directory, 'Spoor transmission failed state directory created');
    ok(-o $spoor_transmission_failed_state_directory, 'Spoor transmission failed state directory owned by effective user');
    is((stat($spoor_transmission_failed_state_directory))[2] & 07777,
      0700,
      'Spoor transmission failed state directory has correct permissions'
    );
  });

$environment->run_test('creates systemd unit files for the login follower', sub {
    App::Spoor::Installer::install(\%installation_config, $root_path);
    ok(-f $login_follower_unit_file, "Login log follower unit file created: $login_follower_unit_file");
    is(
      path($login_follower_unit_file)->slurp_utf8,
      App::Spoor::LoginUnitFile::contents(),
      'Login unit file contents do not match'
    );
    is((stat($login_follower_unit_file))[2] & 07777,
      0644,
      'Spoor login follower unit file permissions'
    );
  });

$environment->run_test('creates systemd unit files for the access follower', sub {
    App::Spoor::Installer::install(\%installation_config, $root_path);
    ok(-f $access_follower_unit_file, "Access log follower unit file created: $access_follower_unit_file");
    is(
      path($access_follower_unit_file)->slurp_utf8,
      App::Spoor::AccessUnitFile::contents(),
      'Access unit file contents do not match'
    );
    is((stat($access_follower_unit_file))[2] & 07777,
      0644,
      'Spoor access follower unit file permissions'
    );
  });

$environment->run_test('creates systemd unit file for the error follower', sub {
    App::Spoor::Installer::install(\%installation_config, $root_path);
    ok(-f $error_follower_unit_file, "Error log follower unit file created: $error_follower_unit_file");
    is(
      path($error_follower_unit_file)->slurp_utf8,
      App::Spoor::ErrorUnitFile::contents(),
      'Error unit file contents do not match'
    );
    is((stat($error_follower_unit_file))[2] & 07777,
      0644,
      'Spoor error follower unit file permissions'
    );
  });

$environment->run_test('creates systemd unit file for the log transmitter', sub {
    App::Spoor::Installer::install(\%installation_config, $root_path);
    ok(-f $transmitter_unit_file, "Transmitter unit file created: $transmitter_unit_file");
    is(
      path($transmitter_unit_file)->slurp_utf8,
      App::Spoor::TransmitterUnitFile::contents(),
      'Transmitter unit file contents do not match'
    );
    is((stat($transmitter_unit_file))[2] & 07777,
      0644,
      'Spoor transmitter unit file permissions'
    );
  });

$environment->run_test('creates the hook file in the cpanel directory', sub {
    App::Spoor::Installer::install(\%installation_config, $root_path);
    is(
      (stat("$root_path/var/cpanel/perl5"))[2] & 07777,
      0755,
      'Perl5 dir permissions'
    );
    is(
      (stat("$root_path/var/cpanel/perl5/lib"))[2] & 07777,
      0755,
      'Perl5 lib dir permissions'
    );
    ok(-f $cpanel_hook_file_path, 'Cpanel Hook File');
    is(
      path($cpanel_hook_file_path)->slurp_utf8,
      App::Spoor::CpanelHookFile::contents('/var/log/spoor_forward'),
      'Hook file contents'
    );
    is((stat($cpanel_hook_file_path))[2] & 07777,
      0644,
      'Cpanel hook file permissions'
    );
  });

done_testing();
