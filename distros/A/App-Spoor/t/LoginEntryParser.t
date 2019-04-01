use strict;
use warnings;
use v5.10;

use Test::More;

use DateTime;

BEGIN {
  use_ok('App::Spoor::LoginEntryParser') || print "Could not load App::Spoor::LoginEntryParser\n";
}

ok (defined(&App::Spoor::LoginEntryParser::parse), 'App::Spoor::LoginEntryParser::parse is defined');

my $successful_webmaild_login = '[2018-09-19 16:02:36 +0000] info [webmaild] 10.10.10.10 ' . 
  '- rorymckinley@blah.capefox.co (possessor: blahuser) - SUCCESS LOGIN webmaild';
my %parsed_successful_webmaild_login = (
  type => 'login',
  event => 'login',
  log_time => DateTime->new(
    year => 2018,
    month => 9,
    day => 19,
    hour => 16,
    minute => 2,
    second => 36,
    time_zone => '+0000'
  )->epoch(),
  scope => 'webmaild',
  ip => '10.10.10.10',
  credential => 'rorymckinley@blah.capefox.co',
  possessor => 'blahuser',
  status => 'success',
  context => 'mailbox'
);

is_deeply(
  App::Spoor::LoginEntryParser::parse($successful_webmaild_login),
  \%parsed_successful_webmaild_login,
	'Parses a successful webmaild login'
);

is_deeply(
  App::Spoor::LoginEntryParser::parse("$successful_webmaild_login\n"),
  \%parsed_successful_webmaild_login,
	'Parses a successful webmaild login with a trailing newline');

my $successful_webmaild_login_domain_level = '[2018-09-19 16:02:36 +0000] info [webmaild] 10.10.10.10 ' . 
  '- foobarbazzle (possessor: blahuser) - SUCCESS LOGIN webmaild';
my %parsed_successful_webmaild_login_domain_level = (
  type => 'login',
  event => 'login',
  log_time => DateTime->new(
    year => 2018,
    month => 9,
    day => 19,
    hour => 16,
    minute => 2,
    second => 36,
    time_zone => '+0000'
  )->epoch(),
  scope => 'webmaild',
  ip => '10.10.10.10',
  credential => 'foobarbazzle',
  possessor => 'blahuser',
  status => 'success',
  context => 'domain'
);

is_deeply(
  App::Spoor::LoginEntryParser::parse($successful_webmaild_login_domain_level),
  \%parsed_successful_webmaild_login_domain_level,
	'Parses a successful webmaild login at domain level'
);

is_deeply(
  App::Spoor::LoginEntryParser::parse("$successful_webmaild_login_domain_level\n"),
  \%parsed_successful_webmaild_login_domain_level,
	'Parses a successful webmaild login at domain level with a trailing newline');

my $successful_whm_login = '[2018-10-12 12:38:31 +0000] info [whostmgrd] 10.10.10.10 ' .
  '- root - SUCCESS LOGIN whostmgrd';
my %parsed_successful_whm_login = (
  type => 'login',
  event => 'login',
  log_time => DateTime->new(
    year => 2018,
    month => 10,
    day => 12,
    hour => 12,
    minute => 38,
    second => 31,
    time_zone => '+0000'
  )->epoch(),
  scope => 'whostmgrd',
  ip => '10.10.10.10',
  credential => 'root',
  status => 'success',
  context => 'system'
);

is_deeply(
  App::Spoor::LoginEntryParser::parse("$successful_whm_login"),
  \%parsed_successful_whm_login,
	'Parses a successful whm login');

is_deeply(
  App::Spoor::LoginEntryParser::parse("$successful_whm_login\n"),
  \%parsed_successful_whm_login,
	'Parses a successful whm login with trailing newline');

my $successful_cpanel_login = '[2018-10-14 06:40:21 +0000] info [cpaneld] 10.10.10.10 ' .
  '- blahuser - SUCCESS LOGIN cpaneld';
my %parsed_successful_cpanel_login = (
  type => 'login',
  event => 'login',
  log_time => DateTime->new(
    year => 2018,
    month => 10,
    day => 14,
    hour => 6,
    minute => 40,
    second => 21,
    time_zone => '+0000'
  )->epoch(),
  scope => 'cpaneld',
  ip => '10.10.10.10',
  credential => 'blahuser',
  status => 'success',
  context => 'domain'
);

is_deeply(
  App::Spoor::LoginEntryParser::parse($successful_cpanel_login),
  \%parsed_successful_cpanel_login,
	'Parses a successful cpanel login'
);

is_deeply(
  App::Spoor::LoginEntryParser::parse("$successful_cpanel_login\n"),
  \%parsed_successful_cpanel_login,
	'Parses a successful cpanel login with trailing newline'
);

my $deferred_whm_login = '[2018-10-14 09:09:12 +0000] info [whostmgrd] 10.10.10.10 ' .
  '- root "GET / HTTP/1.1" DEFERRED LOGIN whostmgrd: security token missing';
my %parsed_deferred_whm_login = (
  type => 'login',
  event => 'login',
  log_time => DateTime->new(
    year => 2018,
    month => 10,
    day => 14,
    hour => 9,
    minute => 9,
    second => 12,
    time_zone => '+0000'
  )->epoch(),
  scope => 'whostmgrd',
  ip => '10.10.10.10',
  credential => 'root',
  status => 'deferred',
  message => 'security token missing',
  endpoint => 'GET / HTTP/1.1',
  context => 'system'
);

is_deeply(
  App::Spoor::LoginEntryParser::parse($deferred_whm_login),
  \%parsed_deferred_whm_login,
	'Parses a deferred whm login');

is_deeply(
  App::Spoor::LoginEntryParser::parse("$deferred_whm_login\n"),
  \%parsed_deferred_whm_login,
	'Parses a deferred whm login with trailing newline');

my $failed_cpaneld_login = '[2018-10-15 15:42:18 +0000] info [cpaneld] 10.10.10.10 ' .
  '- cpresellercapefo "POST /login/?login_only=1 HTTP/1.1" FAILED LOGIN cpaneld: ' .
  'access denied for root, reseller, and user password';
my %parsed_failed_cpanel_login = (
  type => 'login',
  event => 'login',
  log_time => DateTime->new(
    year => 2018,
    month => 10,
    day => 15,
    hour => 15,
    minute => 42,
    second => 18,
    time_zone => '+0000'
  )->epoch(),
  scope => 'cpaneld',
  ip => '10.10.10.10',
  credential => 'cpresellercapefo',
  status => 'failed',
  message => 'access denied for root, reseller, and user password',
  endpoint => 'POST /login/?login_only=1 HTTP/1.1',
  context => 'domain'
);

is_deeply(
  App::Spoor::LoginEntryParser::parse($failed_cpaneld_login),
  \%parsed_failed_cpanel_login,
	'Parses a failed cpanel login');

is_deeply(
  App::Spoor::LoginEntryParser::parse("$failed_cpaneld_login\n"),
  \%parsed_failed_cpanel_login,
	'Parses a failed cpanel login with a trailing newline');

done_testing();
