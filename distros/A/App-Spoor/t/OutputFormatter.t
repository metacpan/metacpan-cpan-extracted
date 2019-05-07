
use strict;
use warnings;
use utf8;

use Test::More;
use Test::SetupTeardown;

use File::Path qw(remove_tree);

use Text::CSV qw( csv );

my $test_directory_path = '/tmp/app_spoor_test_root/';
my $test_output_path =  $test_directory_path . 'output_formatter_output.csv';
my $test_output;

sub setup {
  mkdir($test_directory_path, 0744);
  open $test_output, '>', $test_output_path;
}

sub test_print {
  my $output_type = shift;
  my $records = shift;
  my $output_file = shift;

  my @formatted_records = (
    ['foo', 'bar'],
    ['shnazzle', 'snafu']
  );

  my $csv = Text::CSV->new({ eol => $/ });

  foreach my $record (@formatted_records) {
    $csv->print($output_file, $record);
  }
}

sub teardown {
  remove_tree($test_directory_path);
  close $test_output;
}

BEGIN {
  use_ok('App::Spoor::OutputFormatter') || print "Could not load App::Spoor::OutputFormatter\n";
}

ok (defined(&App::Spoor::OutputFormatter::print), 'App::Spoor::OutputFormatter::print is defined');

my $environment = Test::SetupTeardown->new(setup => \&setup, teardown => \&teardown);

my @reports_data = (
  {
    id => '456-GHI',
    event_time => 1555588110,
    host => 'spoor2.test.com',
    type => 'forward_removed',
    mailbox_address => 'anothervictim@test.com'
  },
  {
    id => '123-ABC',
    event_time => 1555513150,
    host => 'spoor.test.com',
    type => 'login',
    mailbox_address => 'victim@test.com'
  },
);

my @expected_csv_reports_output = (
  ['id', 'event time', 'host', 'event type', 'mailbox address'],
  ['456-GHI','2019-04-18 11:48:30 +0000', 'spoor2.test.com', 'forward_removed', 'anothervictim@test.com'],
  ['123-ABC','2019-04-17 14:59:10 +0000', 'spoor.test.com', 'login', 'victim@test.com'],
);

$environment->run_test('Correctly outputs report listings', sub {
    App::Spoor::OutputFormatter::print('report', \@reports_data, $test_output);
    close $test_output;
    is_deeply(csv(in => $test_output_path), \@expected_csv_reports_output, 'Report CSV output matches');
  });

my @mailbox_events_data = (
  {
    id => '456-GHI',
    host => 'spoor2.test.com',
    mailbox_address => 'anothervictim@test.com',
    ip => '10.1.1.2',
    event_time => 1555588110,
    type => 'forward_removed'
  },
  {
    id => '123-ABC',
    host => 'spoor.test.com',
    mailbox_address => 'victim@test.com',
    ip => '10.1.1.1',
    event_time => 1555513150,
    type => 'login'
  }
);

my @expected_csv_mailbox_events_output = (
  ['id', 'event time', 'host', 'event type', 'mailbox address', 'ip'],
  ['456-GHI','2019-04-18 11:48:30 +0000', 'spoor2.test.com', 'forward_removed', 'anothervictim@test.com', '10.1.1.2'],
  ['123-ABC','2019-04-17 14:59:10 +0000', 'spoor.test.com', 'login', 'victim@test.com', '10.1.1.1'],
);

$environment->run_test('Correctly outputs report listings', sub {
    App::Spoor::OutputFormatter::print('mailbox_event', \@mailbox_events_data, $test_output);
    close $test_output;
    is_deeply(csv(in => $test_output_path), \@expected_csv_mailbox_events_output, 'Mailbox Event CSV output matches');
  });

done_testing();
