use strict;
use warnings;
use v5.10;

use Test::More;
use Test::SetupTeardown;

use Path::Tiny qw(path);
use File::Path qw(remove_tree);
use JSON;

my %file_contents_1 = (
  foo => 'bar'
);
my %file_contents_2 = (
  bar => 'baz'
);
my %file_contents_3 = (
  buzz => 'biz'
);
my %file_contents_bad = (
  bad => 'hombres'
);

my $parsed_file_path_1 = '/tmp/app_spoor_test_root/var/lib/spoor/parsed/access.1.2.json';
my $parsed_file_path_2 = '/tmp/app_spoor_test_root/var/lib/spoor/parsed/login.3.4.json';
my $parsed_file_path_3 = '/tmp/app_spoor_test_root/var/lib/spoor/parsed/error.5.6.json';

my $transmitted_file_path_1 = '/tmp/app_spoor_test_root/var/lib/spoor/transmitted/access.1.2.json';
my $transmitted_file_path_2 = '/tmp/app_spoor_test_root/var/lib/spoor/transmitted/login.3.4.json';
my $transmitted_file_path_3 = '/tmp/app_spoor_test_root/var/lib/spoor/transmitted/error.5.6.json';

my $transmission_failed_file_path_1 = '/tmp/app_spoor_test_root/var/lib/spoor/transmission_failed/access.1.2.json';
my $transmission_failed_file_path_2 = '/tmp/app_spoor_test_root/var/lib/spoor/transmission_failed/login.3.4.json';
my $transmission_failed_file_path_3 = '/tmp/app_spoor_test_root/var/lib/spoor/transmission_failed/error.5.6.json';

my $parsed_file_path_bad_format_1 = '/tmp/app_spoor_test_root/var/lib/spoor/parsed/foo.1.2.json';
my $parsed_file_path_bad_format_2 = '/tmp/app_spoor_test_root/var/lib/spoor/parsed/login.a.4.json';
my $parsed_file_path_bad_format_3 = '/tmp/app_spoor_test_root/var/lib/spoor/parsed/error.5.b.json';
my $parsed_file_path_bad_format_4 = '/tmp/app_spoor_test_root/var/lib/spoor/parsed/error5.6.json';
my $parsed_file_path_bad_format_5 = '/tmp/app_spoor_test_root/var/lib/spoor/parsed/error.56.json';
my $parsed_file_path_bad_format_6 = '/tmp/app_spoor_test_root/var/lib/spoor/parsed/error.5.6json';
my $parsed_file_path_bad_format_7 = '/tmp/app_spoor_test_root/var/lib/spoor/parsed/error.5.6.foo';

my $transmitted_file_path_bad_format_1 = '/tmp/app_spoor_test_root/var/lib/spoor/transmitted/foo.1.2.json';
my $transmitted_file_path_bad_format_2 = '/tmp/app_spoor_test_root/var/lib/spoor/transmitted/login.a.4.json';
my $transmitted_file_path_bad_format_3 = '/tmp/app_spoor_test_root/var/lib/spoor/transmitted/error.5.b.json';
my $transmitted_file_path_bad_format_4 = '/tmp/app_spoor_test_root/var/lib/spoor/transmitted/error5.6.json';
my $transmitted_file_path_bad_format_5 = '/tmp/app_spoor_test_root/var/lib/spoor/transmitted/error.56.json';
my $transmitted_file_path_bad_format_6 = '/tmp/app_spoor_test_root/var/lib/spoor/transmitted/error.5.6json';
my $transmitted_file_path_bad_format_7 = '/tmp/app_spoor_test_root/var/lib/spoor/transmitted/error.5.6.foo';

my %config = (
  parsed_entries_path => '/tmp/app_spoor_test_root/var/lib/spoor/parsed',
  transmitted_entries_path => '/tmp/app_spoor_test_root/var/lib/spoor/transmitted',
  transmission_failed_entries_path => '/tmp/app_spoor_test_root/var/lib/spoor/transmission_failed',
);

my @transmitted_contents = ();
my @checked_paths = ();

sub setup {
  @transmitted_contents = ();
  @checked_paths = ();

  mkdir('/tmp/app_spoor_test_root', 0744);
  mkdir('/tmp/app_spoor_test_root/var', 0744);
  mkdir('/tmp/app_spoor_test_root/var/lib', 0744);
  mkdir('/tmp/app_spoor_test_root/var/lib/spoor', 0744);
  mkdir('/tmp/app_spoor_test_root/var/lib/spoor/parsed', 0744);

  path($parsed_file_path_1)->spew_utf8(to_json(\%file_contents_1));
  path($parsed_file_path_2)->spew_utf8(to_json(\%file_contents_2));
  path($parsed_file_path_3)->spew_utf8(to_json(\%file_contents_3));

  path($parsed_file_path_bad_format_1)->spew_utf8(to_json(\%file_contents_bad));
  path($parsed_file_path_bad_format_2)->spew_utf8(to_json(\%file_contents_bad));
  path($parsed_file_path_bad_format_3)->spew_utf8(to_json(\%file_contents_bad));
  path($parsed_file_path_bad_format_4)->spew_utf8(to_json(\%file_contents_bad));
  path($parsed_file_path_bad_format_5)->spew_utf8(to_json(\%file_contents_bad));
  path($parsed_file_path_bad_format_6)->spew_utf8(to_json(\%file_contents_bad));
  path($parsed_file_path_bad_format_7)->spew_utf8(to_json(\%file_contents_bad));

  mkdir('/tmp/app_spoor_test_root/var/lib/spoor/transmission_failed', 0744);
  mkdir('/tmp/app_spoor_test_root/var/lib/spoor/transmitted', 0744);

}

sub teardown {
  remove_tree('/tmp/app_spoor_test_root');
}

sub transmitter {
  my $data = shift;
  if (exists $data->{foo}) {
    push @transmitted_contents, 'foo';
  } elsif (exists $data->{bar}) {
    push @transmitted_contents, 'bar';
  } elsif (exists $data->{buzz}) {
    push @transmitted_contents, 'buzz';
  } elsif (exists $data->{bad}) {
    push @transmitted_contents, 'bad';
  }
  
}

sub security_check {
  push @checked_paths, shift @_ ;
}

BEGIN {
  use_ok('App::Spoor::ParsedFileManager') || print "Could not load App::Spoor::ParsedFileManager\n";
}

ok(defined(&App::Spoor::ParsedFileManager::process_parsed_files), 'process_parsed_files is not defined');

my $environment = Test::SetupTeardown->new(setup => \&setup, teardown => \&teardown);

$environment->run_test('Passes the file contents to the transmitter', sub {
    App::Spoor::ParsedFileManager::process_parsed_files(\%config, \&security_check, \&transmitter);
    my @sorted_transmitted_contents = sort @transmitted_contents;
    is_deeply(\@sorted_transmitted_contents, ['bar', 'buzz', 'foo'], 'All file contents passed in');
  });

$environment->run_test('Moves the transmitted files', sub {
    App::Spoor::ParsedFileManager::process_parsed_files(\%config, \&security_check, \&transmitter);

    ok(-f $transmitted_file_path_1, 'File 1 exists in the transmitted directory');
    ok((not -f $parsed_file_path_1), 'File 1 does not exist in the parsed directory');

    ok(-f $transmitted_file_path_2, 'File 2 exists in the transmitted directory');
    ok((not -f $parsed_file_path_2), 'File 2 does not exist in the parsed directory');

    ok(-f $transmitted_file_path_3, 'File 3 exists in the transmitted directory');
    ok((not -f $parsed_file_path_3), 'File 3 does not exist in the parsed directory');
  });

$environment->run_test('Performs a security check on the file about to be transmitted', sub {
    my @expected_paths = sort ($parsed_file_path_1, $parsed_file_path_2, $parsed_file_path_3);

    App::Spoor::ParsedFileManager::process_parsed_files(\%config, \&security_check, \&transmitter);

    my @sorted_checked_paths = sort @checked_paths;
    is_deeply(
      \@sorted_checked_paths,
      \@expected_paths,
      'All files were passed to the security check'
    );
  });

$environment->run_test('Moves files that had transmission failures', sub {
    App::Spoor::ParsedFileManager::process_parsed_files(\%config, \&security_check, sub { 0 });

    ok((not -f $parsed_file_path_1), 'File 1 does not exist in the parsed directory');
    ok(-f $transmission_failed_file_path_1, 'File 1 exists in the transmission_failed directory');

    ok((not -f $parsed_file_path_2), 'File 2 does not exist in the parsed directory');
    ok(-f $transmission_failed_file_path_2, 'File 2 exists in the transmission_failed directory');

    ok((not -f $parsed_file_path_3), 'File 3 does not exist in the parsed directory');
    ok(-f $transmission_failed_file_path_3, 'File 3 exists in the transmission_failed directory');
  });

$environment->run_test('Does not transmit files that fail the security check', sub {
    App::Spoor::ParsedFileManager::process_parsed_files(\%config, sub { 0 }, \&transmitter);

    is_deeply(\@transmitted_contents, [], 'No files were transmitted');

    ok((not -f $transmitted_file_path_1), 'File 1 does not exist in the transmitted directory');
    ok((not -f $transmitted_file_path_2), 'File 2 does not exist in the transmitted directory');
    ok((not -f $transmitted_file_path_3), 'File 3 does not exist in the transmitted directory');
  });

$environment->run_test('Does not move files that fail the security check', sub {
    App::Spoor::ParsedFileManager::process_parsed_files(\%config, sub { 0 }, \&transmitter);

    ok(-f $parsed_file_path_1, 'File 1 exists in the parsed directory');
    ok(-f $parsed_file_path_2, 'File 2 exists in the parsed directory');
    ok(-f $parsed_file_path_3, 'File 3 exists in the parsed directory');
  });

$environment->run_test('Does not move files that do not have appropriately formatted names', sub {
    App::Spoor::ParsedFileManager::process_parsed_files(\%config, \&security_check, \&transmitter);

    ok(-f $parsed_file_path_bad_format_1, 'Bad format File 1 exists in the parsed directory');
    ok((not -f $transmitted_file_path_bad_format_1), 'Bad format File 1 does not exist in the transmitted directory');

    ok(-f $parsed_file_path_bad_format_2, 'Bad format File 2 exists in the parsed directory');
    ok((not -f $transmitted_file_path_bad_format_2), 'Bad format File 2 does not exist in the transmitted directory');

    ok(-f $parsed_file_path_bad_format_3, 'Bad format File 3 exists in the parsed directory');
    ok((not -f $transmitted_file_path_bad_format_3), 'Bad format File 3 does not exist in the transmitted directory');

    ok(-f $parsed_file_path_bad_format_4, 'Bad format File 4 exists in the parsed directory');
    ok((not -f $transmitted_file_path_bad_format_4), 'Bad format File 4 does not exist in the transmitted directory');

    ok(-f $parsed_file_path_bad_format_5, 'Bad format File 5 exists in the parsed directory');
    ok((not -f $transmitted_file_path_bad_format_5), 'Bad format File 5 does not exist in the transmitted directory');

    ok(-f $parsed_file_path_bad_format_6, 'Bad format File 6 exists in the parsed directory');
    ok((not -f $transmitted_file_path_bad_format_6), 'Bad format File 6 does not exist in the transmitted directory');

    ok(-f $parsed_file_path_bad_format_7, 'Bad format File 7 exists in the parsed directory');
    ok((not -f $transmitted_file_path_bad_format_7), 'Bad format File 7 does not exist in the transmitted directory');
  });

done_testing();
