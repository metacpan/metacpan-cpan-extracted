
use warnings;
use v5.10;

use Test::More;
use Test::SetupTeardown;

use File::Path qw(remove_tree);
use YAML::Tiny;

my $root_path = '/tmp/app_spoor_test_root';

my %config_contents = (
  application => {
    parsed_entries_path => "foo/bar",
    transmitted_entries_path => "foo/baz",
    ignored_entries_path => "foo/bazzle"
  },
  followers => {
    login => {
      name => '/foo/bar/baz/login',
      maxinterval => 20,
      debug => 0,
      transformer => 'bah',
    },
    access => {
      name => '/foo/bar/baz/access',
      maxinterval => 50,
      debug => 1,
      transformer => 'foo',
    }
  },
  transmission => {
    credentials => {
      api_identifier => 'user123',
      api_secret => 'secret',
    },
    host => 'https://spoor.capefox.co',
    endpoints => {
      report => '/api/reports',
      partial_report_log => '/api/partial_reports/log',
    }
  }
);

sub populate_config_file {
  my $config = YAML::Tiny->new(shift @_);
  my $root_path = shift @_;

  $config->write("$root_path/etc/spoor/spoor.yml");
  chmod(0600,  "$root_path/etc/spoor/spoor.yml");
}

sub setup {
  mkdir($root_path, 0744);
  mkdir("$root_path/etc", 0744);
  mkdir("$root_path/etc/spoor", 0744);
  &populate_config_file(\%config_contents, $root_path);
}

sub teardown {
  remove_tree($root_path);
}

my $environment = Test::SetupTeardown->new(setup => \&setup, teardown => \&teardown);

BEGIN {
  use_ok('App::Spoor::Config') || print "Could not load App::Spoor::Config\n";
}

ok (defined(&App::Spoor::Config::get_follower_config), 'App::Spoor::Config::get_follower_config is defined');

$environment->run_test('retrieves follower config', sub {
    is_deeply(
      App::Spoor::Config::get_follower_config('login', $root_path),
      $config_contents{'followers'}->{'login'},
      'Fetches appropriate follower config'
    );
  });

ok (defined(&App::Spoor::Config::get_application_config), 'App::Spoor::Config::get_application_config is defined');

$environment->run_test('returns hardcoded application config', sub {
    is_deeply(
      App::Spoor::Config::get_application_config($root_path),
      {
        parsed_entries_path => '/var/lib/spoor/parsed', 
        transmitted_entries_path => '/var/lib/spoor/transmitted', 
        transmission_failed_entries_path => '/var/lib/spoor/transmission_failed', 
      },
      'Fetches application config'
    );
  });

ok (defined(&App::Spoor::Config::get_transmission_config), 'App::Spoor::Config::get_transmission_config is defined');

$environment->run_test('retrieves transmission config', sub {
    is_deeply(
      App::Spoor::Config::get_transmission_config($root_path),
      $config_contents{'transmission'},
      'Fetches transmission config'
    );
  });
done_testing();
