use strict;
use warnings;
use utf8;
use v5.10;

use Test::More;

use App::Spoor::TransmissionFormatter;

use DateTime;

my $host = 'foo.host.com';

my %login_entry = (
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
  context => 'foobar'
);

my %formatted_login_entry = (
  type => 'login',
  time => $login_entry{log_time},
  ip => $login_entry{ip},
  mailbox_address => $login_entry{credential},
  context => $login_entry{context},
  host => $host
);

my %forward_added_partial_entry_ip = (
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
  context => 'foobar',
  event => 'forward_added_partial_ip',
  status => 'success',
);

my %formatted_forward_added_partial_entry_ip = (
  type => 'forward_added_partial_ip',
  ip => $forward_added_partial_entry_ip{ip},
  time => $forward_added_partial_entry_ip{log_time},
  mailbox_address => $forward_added_partial_entry_ip{credential},
  context => $forward_added_partial_entry_ip{context},
  host => $host
);

my %forward_added_partial_entry_recipient = (
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
  context => 'barbaz',
  email => 'victim@spoor.test',
  forward_to => 'dodgy@dodgydomain.test',
  forward_type => 'email',
  status => 'success',
);

my %formatted_forward_added_partial_entry_recipient = (
  type => 'forward_added_partial_recipient',
  time => $forward_added_partial_entry_recipient{log_time},
  mailbox_address => $forward_added_partial_entry_recipient{email},
  forward_recipient => $forward_added_partial_entry_recipient{forward_to},
  context => $forward_added_partial_entry_recipient{context},
  host => $host
);

my %forward_removed = (
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
  forward_recipient => 'rorymckinley+cpanel@blah.com',
  status => 'success'
);

my %formatted_forward_removed = (
  type => 'forward_removed',
  time => $forward_removed{log_time},
  mailbox_address => $forward_removed{credential},
  forward_recipient => $forward_removed{forward_recipient},
  ip => $forward_removed{ip},
  context => $forward_removed{context},
  host => $host
);

BEGIN {
  use_ok('App::Spoor::TransmissionFormatter') || print('Could not load App::Spoor::TransmissionFormatter');
}

ok(defined(&App::Spoor::TransmissionFormatter::format), 'App::Spoor::TransmissionFormatter::format is not defined');

is_deeply(
  App::Spoor::TransmissionFormatter::format(\%login_entry, $host),
  \%formatted_login_entry,
  'Login entry is correctly formatted'
);

is_deeply(
  App::Spoor::TransmissionFormatter::format(\%forward_added_partial_entry_ip, $host),
  \%formatted_forward_added_partial_entry_ip,
  'Partial entry with an IP is correctly formatted'
);

is_deeply(
  App::Spoor::TransmissionFormatter::format(\%forward_added_partial_entry_recipient, $host),
  \%formatted_forward_added_partial_entry_recipient,
  'Partial entry with a recipient is correctly formatted'
);

is_deeply(
  App::Spoor::TransmissionFormatter::format(\%forward_removed, $host),
  \%formatted_forward_removed,
  'Forward removed entry is correctly formatted'
);

done_testing();
