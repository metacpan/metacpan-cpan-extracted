use strict;
use warnings;
use v5.10;

use Test::More;

use JSON;

use DateTime;

BEGIN {
  use_ok('App::Spoor::ErrorEntryParser') || print("Could not load App::Spoor::ErrorEntryParse\n");
}

ok(defined(&App::Spoor::ErrorEntryParser::parse), 'App::Spoor::ErrorEntryParser::parse is not defined');

my $json;
my $entry;
my %expected_parsed_entry;

my %webmail_forward_added_data = (
  args => {
    fwdsystem => '',
    email => 'victim',
    failmsgs => '',
    domain => '',
    fwdemail => 'dodgy@dodgydomain.test',
    pipefwd => '',
    fwdopt => 'fwd'
  },
  result => [
    {forward => 'dodgy@dodgydomain.test', domain => 'spoor.test', email => 'victim@spoor.test'}
  ],
  user => 'spoortest'
);

$json = to_json(\%webmail_forward_added_data);
$entry = "[2019-02-10 10:24:17 +0000] info [spoor_forward_added] $json";

%expected_parsed_entry = (
  type => 'error',
  event => 'forward_added_partial_recipient',
  log_time => DateTime->new(
    year => 2019,
    month => 2,
    day => 10,
    hour => 10,
    minute => 24,
    second => 17,
    time_zone => '+0000'
  )->epoch(),
  context => 'mailbox',
  email => 'victim@spoor.test',
  forward_to => 'dodgy@dodgydomain.test',
  forward_type => 'email',
  status => 'success',
);

is_deeply(
  App::Spoor::ErrorEntryParser::parse($entry),
  \%expected_parsed_entry,
  'Webmail forward added'
);
is_deeply(
  App::Spoor::ErrorEntryParser::parse("$entry\n"),
  \%expected_parsed_entry,
  'Webmail forward added - trailing newline'
);

my %domain_level_forward_data = (
  args => {
    fwdsystem => '',
    email => 'victim',
    failmsgs => '',
    domain => 'spoor.test',
    fwdemail => 'dodgy@dodgydomain.test',
    pipefwd => '',
    fwdopt => 'fwd'
  },
  result => [
    {forward => 'dodgy@dodgydomain.test', domain => 'spoor.test', email => 'victim@spoor.test'}
  ],
  user => 'spoortest'
);

$json = to_json(\%domain_level_forward_data);
$entry = "[2019-02-10 10:24:17 +0000] info [spoor_forward_added] $json";

%expected_parsed_entry = (
  type => 'error',
  event => 'forward_added_partial_recipient',
  log_time => DateTime->new(
    year => 2019,
    month => 2,
    day => 10,
    hour => 10,
    minute => 24,
    second => 17,
    time_zone => '+0000'
  )->epoch(),
  context => 'domain',
  email => 'victim@spoor.test',
  forward_to => 'dodgy@dodgydomain.test',
  forward_type => 'email',
  status => 'success',
);

is_deeply(
  App::Spoor::ErrorEntryParser::parse($entry),
  \%expected_parsed_entry,
  'Domain level forward added'
);
is_deeply(
  App::Spoor::ErrorEntryParser::parse("$entry\n"),
  \%expected_parsed_entry,
  'Domain level forward added - trailing newline'
);

my %system_user_forward_data = (
  args => {
    fwdsystem => 'dodgysystemuser',
    email => 'victim',
    failmsgs => '',
    domain => 'spoor.test',
    fwdemail => '',
    pipefwd => '',
    fwdopt => 'system'
  },
  result => [
    {forward => 'dodgysystemuser', domain => 'spoor.test', email => 'victim@spoor.test'}
  ],
  user => 'spoortest'
);

$json = to_json(\%system_user_forward_data);
$entry = "[2019-02-10 10:24:17 +0000] info [spoor_forward_added] $json";

%expected_parsed_entry = (
  type => 'error',
  event => 'forward_added_partial_recipient',
  log_time => DateTime->new(
    year => 2019,
    month => 2,
    day => 10,
    hour => 10,
    minute => 24,
    second => 17,
    time_zone => '+0000'
  )->epoch(),
  context => 'domain',
  email => 'victim@spoor.test',
  forward_to => 'dodgysystemuser',
  forward_type => 'system_user',
  status => 'success',
);

is_deeply(
  App::Spoor::ErrorEntryParser::parse($entry),
  \%expected_parsed_entry,
  'System user forward added'
);
is_deeply(
  App::Spoor::ErrorEntryParser::parse("$entry\n"),
  \%expected_parsed_entry,
  'System user forward added - trailing newline'
);

my %pipe_to_script_forward_data = (
  args => {
    fwdsystem => '',
    email => 'victim',
    failmsgs => '',
    domain => 'spoor.test',
    fwdemail => '',
    pipefwd => '/dev/null',
    fwdopt => 'pipe'
  },
  result => [
    {forward => '|/dev/null', domain => 'spoor.test', email => 'victim@spoor.test'}
  ],
  user => 'spoortest'
);

$json = to_json(\%pipe_to_script_forward_data);
$entry = "[2019-02-10 10:24:17 +0000] info [spoor_forward_added] $json";

%expected_parsed_entry = (
  type => 'error',
  event => 'forward_added_partial_recipient',
  log_time => DateTime->new(
    year => 2019,
    month => 2,
    day => 10,
    hour => 10,
    minute => 24,
    second => 17,
    time_zone => '+0000'
  )->epoch(),
  context => 'domain',
  email => 'victim@spoor.test',
  forward_to => '|/dev/null',
  forward_type => 'pipe',
  status => 'success',
);

is_deeply(
  App::Spoor::ErrorEntryParser::parse($entry),
  \%expected_parsed_entry,
  'System user forward'
);
is_deeply(
  App::Spoor::ErrorEntryParser::parse("$entry\n"),
  \%expected_parsed_entry,
  'System user forward- trailing newline'
);

$entry = "[2019-02-10 10:24:17 +0000] info [notspoor] blah";

%expected_parsed_entry = (
  type => 'error',
  event => 'unrecognised'
);

is_deeply(
  App::Spoor::ErrorEntryParser::parse("$entry"),
  \%expected_parsed_entry,
  'Unrecognised entry'
);
is_deeply(
  App::Spoor::ErrorEntryParser::parse("$entry\n"),
  \%expected_parsed_entry,
  'Unrecognised entry'
);

done_testing();
