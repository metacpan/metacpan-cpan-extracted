use strict;
use warnings;
use utf8;
use v5.10;

use Test::More;

BEGIN {
  use_ok('App::Spoor::AccessEntryParser') || print "Could not load App::Spoor::AccessEntryParser\n";
}

ok(defined(&App::Spoor::AccessEntryParser::parse), 'App::Spoor::AccessEntryParser::parse is defined');

my $access_log_entry_forward_added = '10.10.10.10 - rorymckinley%40blah.capefox.co [10/15/2018:17:47:27 -0000] ' .
  '"POST /cpsess0248462691/webmail/paper_lantern/mail/doaddfwd.html HTTP/1.1" 200 0 "https://cp4.capefox.co:2096/" ' .
  '"Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0" "s" "-" 2096';
my %parsed_log_entry_forward_added = (
  type => 'access',
  ip => '10.10.10.10',
  credential => 'rorymckinley@blah.capefox.co',
  log_time => DateTime->new(
    year => 2018,
    month => 10,
    day => 15,
    hour => 17,
    minute => 47,
    second => 27,
    time_zone => '-0000'
  )->epoch(),
  context => 'mailbox',
  event => 'forward_added_partial_ip',
  status => 'success'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse($access_log_entry_forward_added),
  \%parsed_log_entry_forward_added,
  'Parses an access log entry - adding a forward'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse("$access_log_entry_forward_added\n"),
  \%parsed_log_entry_forward_added,
  'Parses an access log entry - adding a forward with a trailing newline'
);

my $access_log_entry_not_mailbox_level = '10.10.10.10 - foo [10/15/2018:17:47:27 -0000] ' .
  '"POST /cpsess0248462691/webmail/paper_lantern/mail/doaddfwd.html HTTP/1.1" 200 0 "https://cp4.capefox.co:2096/" ' .
  '"Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0" "s" "-" 2096';
my %parsed_log_entry_not_mailbox_level = (
  type => 'access',
  ip => '10.10.10.10',
  credential => 'foo',
  log_time => DateTime->new(
    year => 2018,
    month => 10,
    day => 15,
    hour => 17,
    minute => 47,
    second => 27,
    time_zone => '-0000'
  )->epoch(),
  context => 'unrecognised',
  event => 'unrecognised',
  status => 'success'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse($access_log_entry_not_mailbox_level),
  \%parsed_log_entry_not_mailbox_level,
  'Parses an access log entry - not mailbox level'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse("$access_log_entry_not_mailbox_level\n"),
  \%parsed_log_entry_not_mailbox_level,
  'Parses an access log entry - not mailbox level with a trailing newline'
);

my $access_log_entry_incorrect_verb = '10.10.10.10 - rorymckinley%40blah.capefox.co [10/15/2018:17:47:27 -0000] ' .
  '"GET /cpsess0248462691/webmail/paper_lantern/mail/doaddfwd.html HTTP/1.1" 200 0 "https://cp4.capefox.co:2096/" ' .
  '"Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0" "s" "-" 2096';
my %parsed_log_entry_incorrect_verb = (
  type => 'access',
  ip => '10.10.10.10',
  credential => 'rorymckinley@blah.capefox.co',
  log_time => DateTime->new(
    year => 2018,
    month => 10,
    day => 15,
    hour => 17,
    minute => 47,
    second => 27,
    time_zone => '-0000'
  )->epoch(),
  context => 'mailbox',
  event => 'unrecognised',
  status => 'success'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse($access_log_entry_incorrect_verb),
  \%parsed_log_entry_incorrect_verb,
  'Parses an access log entry - incorrect http verb'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse("$access_log_entry_incorrect_verb\n"),
  \%parsed_log_entry_incorrect_verb,
  'Parses an access log entry - incorrect http verb with a trailing newline'
);

my $access_log_entry_incorrect_endpoint = '10.10.10.10 - rorymckinley%40blah.capefox.co [10/15/2018:17:47:27 -0000] ' .
  '"POST /cpsess0248462691/webmail/paper_lantern/mail/xxxx.html HTTP/1.1" 200 0 "https://cp4.capefox.co:2096/" ' .
  '"Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0" "s" "-" 2096';
my %parsed_log_entry_incorrect_endpoint = (
  type => 'access',
  ip => '10.10.10.10',
  credential => 'rorymckinley@blah.capefox.co',
  log_time => DateTime->new(
    year => 2018,
    month => 10,
    day => 15,
    hour => 17,
    minute => 47,
    second => 27,
    time_zone => '-0000'
  )->epoch(),
  context => 'mailbox',
  event => 'unrecognised',
  status => 'success'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse($access_log_entry_incorrect_endpoint),
  \%parsed_log_entry_incorrect_endpoint,
  'Parses an access log entry - incorrect endpoint'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse("$access_log_entry_incorrect_endpoint\n"),
  \%parsed_log_entry_incorrect_endpoint,
  'Parses an access log entry - incorrect endpoint with a trailing newline'
);

my $access_log_entry_non_200_response = '10.10.10.10 - rorymckinley%40blah.capefox.co [10/15/2018:17:47:27 -0000] ' .
  '"POST /cpsess0248462691/webmail/paper_lantern/mail/doaddfwd.html HTTP/1.1" 400 0 "https://cp4.capefox.co:2096/" ' .
  '"Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0" "s" "-" 2096';
my %parsed_log_entry_non_200_response = (
  type => 'access',
  ip => '10.10.10.10',
  credential => 'rorymckinley@blah.capefox.co',
  log_time => DateTime->new(
    year => 2018,
    month => 10,
    day => 15,
    hour => 17,
    minute => 47,
    second => 27,
    time_zone => '-0000'
  )->epoch(),
  context => 'mailbox',
  event => 'forward_added_partial_ip',
  status => 'failed'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse($access_log_entry_non_200_response),
  \%parsed_log_entry_non_200_response,
  'Parses an access log entry - non 200 response'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse("$access_log_entry_non_200_response\n"),
  \%parsed_log_entry_non_200_response,
  'Parses an access log entry - non 200 response with a trailing newline'
);

my $access_log_forward_removed = '10.10.10.10 - rorymckinley%40blah.capefox.co [03/05/2019:10:38:37 -0000] ' .
  '"GET /cpsess9858418447/webmail/paper_lantern/mail/dodelfwd.html?email=rorymckinley%40blah.capefox.co' .
  '&emaildest=rorymckinley%2bcpanel%40gmail.com HTTP/1.1" 200 0 "https://cp6.capefox.co:2096/" ' .
  '"Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.96 ' .
  'Safari/537.36" "s" "-" 2096';

my %parsed_forward_removed = (
  type => 'access',
  ip => '10.10.10.10',
  credential => 'rorymckinley@blah.capefox.co',
  log_time => DateTime->new(
    year => 2019,
    month => 3,
    day => 5,
    hour => 10,
    minute => 38,
    second => 37,
    time_zone => '-0000'
  )->epoch(),
  context => 'mailbox',
  event => 'forward_removed',
  forward_recipient => 'rorymckinley+cpanel@gmail.com',
  status => 'success'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse($access_log_forward_removed),
  \%parsed_forward_removed,
  'Parses an access log entry - removing a forward'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse("$access_log_forward_removed\n"),
  \%parsed_forward_removed,
  'Parses an access log entry - removing a forward with a trailing newline'
);

my $access_log_forward_removed_not_mailbox = '10.10.10.10 - foobar [03/05/2019:10:38:37 -0000] ' .
  '"GET /cpsess9858418447/webmail/paper_lantern/mail/dodelfwd.html?email=rorymckinley%40blah.capefox.co' .
  '&emaildest=rorymckinley%2bcpanel%40gmail.com HTTP/1.1" 200 0 "https://cp6.capefox.co:2096/" ' .
  '"Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.96 ' .
  'Safari/537.36" "s" "-" 2096';

my %parsed_forward_removed_not_mailbox = (
  type => 'access',
  ip => '10.10.10.10',
  credential => 'foobar',
  log_time => DateTime->new(
    year => 2019,
    month => 3,
    day => 5,
    hour => 10,
    minute => 38,
    second => 37,
    time_zone => '-0000'
  )->epoch(),
  context => 'unrecognised',
  event => 'unrecognised',
  status => 'success'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse($access_log_forward_removed_not_mailbox),
  \%parsed_forward_removed_not_mailbox,
  'Parses an access log entry - removing a forward not at mailbox level'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse("$access_log_forward_removed_not_mailbox\n"),
  \%parsed_forward_removed_not_mailbox,
  'Parses an access log entry - removing a forward not at mailbox level with a trailing newline - '
);

my $access_log_forward_removed_fail = '10.10.10.10 - rorymckinley%40blah.capefox.co [03/05/2019:10:38:37 -0000] ' .
  '"GET /cpsess9858418447/webmail/paper_lantern/mail/dodelfwd.html?email=rorymckinley%40blah.capefox.co' .
  '&emaildest=rorymckinley%2bcpanel%40gmail.com HTTP/1.1" 400 0 "https://cp6.capefox.co:2096/" ' .
  '"Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.96 ' .
  'Safari/537.36" "s" "-" 2096';

my %parsed_forward_removed_fail = (
  type => 'access',
  ip => '10.10.10.10',
  credential => 'rorymckinley@blah.capefox.co',
  log_time => DateTime->new(
    year => 2019,
    month => 3,
    day => 5,
    hour => 10,
    minute => 38,
    second => 37,
    time_zone => '-0000'
  )->epoch(),
  context => 'mailbox',
  event => 'forward_removed',
  forward_recipient => 'rorymckinley+cpanel@gmail.com',
  status => 'failed'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse($access_log_forward_removed_fail),
  \%parsed_forward_removed_fail,
  'Parses an access log entry - removing a forward failure'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse("$access_log_forward_removed_fail\n"),
  \%parsed_forward_removed_fail,
  'Parses an access log entry - removing a forward failure with a trailing newline - '
);

my $access_log_forward_removed_verb = '10.10.10.10 - rorymckinley%40blah.capefox.co [03/05/2019:10:38:37 -0000] ' .
  '"POST /cpsess9858418447/webmail/paper_lantern/mail/dodelfwd.html?email=rorymckinley%40blah.capefox.co' .
  '&emaildest=rorymckinley%2bcpanel%40gmail.com HTTP/1.1" 200 0 "https://cp6.capefox.co:2096/" ' .
  '"Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.96 ' .
  'Safari/537.36" "s" "-" 2096';

my %parsed_forward_removed_verb = (
  type => 'access',
  ip => '10.10.10.10',
  credential => 'rorymckinley@blah.capefox.co',
  log_time => DateTime->new(
    year => 2019,
    month => 3,
    day => 5,
    hour => 10,
    minute => 38,
    second => 37,
    time_zone => '-0000'
  )->epoch(),
  context => 'mailbox',
  event => 'unrecognised',
  status => 'success'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse($access_log_forward_removed_verb),
  \%parsed_forward_removed_verb,
  'Parses an access log entry - removing a forward with the incorrect verb'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse("$access_log_forward_removed_verb\n"),
  \%parsed_forward_removed_verb,
  'Parses an access log entry - removing a forward with the incorrect verb with a trailing newline'
);

my $access_log_forward_removed_par = '10.10.10.10 - rorymckinley%40blah.capefox.co [03/05/2019:10:38:37 -0000] ' .
  '"GET /cpsess9858418447/webmail/paper_lantern/mail/dodelfwd.html?email=rorymckinley%40blah.capefox.co' .
  ' HTTP/1.1" 200 0 "https://cp6.capefox.co:2096/" ' .
  '"Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.96 ' .
  'Safari/537.36" "s" "-" 2096';

my %parsed_forward_removed_par = (
  type => 'access',
  ip => '10.10.10.10',
  credential => 'rorymckinley@blah.capefox.co',
  log_time => DateTime->new(
    year => 2019,
    month => 3,
    day => 5,
    hour => 10,
    minute => 38,
    second => 37,
    time_zone => '-0000'
  )->epoch(),
  context => 'mailbox',
  event => 'unrecognised',
  status => 'success'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse($access_log_forward_removed_par),
  \%parsed_forward_removed_par,
  'Parses an access log entry - removing a forward emaildest par missing'
);

is_deeply(
  App::Spoor::AccessEntryParser::parse("$access_log_forward_removed_par\n"),
  \%parsed_forward_removed_par,
  'Parses an access log entry - removing a forward emaildest par missing with a trailing newline'
);

done_testing();
