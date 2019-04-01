
use strict;
use warnings;
use utf8;

use Test::More;
use Test::LWP::UserAgent;
use MIME::Base64 qw(encode_base64);
use JSON;

my %config = (
  credentials => {
    api_identifier => 'user123',
    api_secret => 'secret',
  },
  host => 'http://localhost:3000',
  endpoints => {
    report => '/api/reports',
  },
  reporter => 'spoor.test.capefox.co'
);

BEGIN {
  use_ok('App::Spoor::EntryTransmitter') || print('Could not load App::Spoor::EntryTransmitter');
}

ok(defined(&App::Spoor::EntryTransmitter::transmit), 'App::Spoor::EntryTransmitter::transmit is not defined');

my $ua = Test::LWP::UserAgent->new;

my %login_data = (
  type => 'login',
  foo => 'bar'
);

my %submitted_login_content = (
  report => {
    entries => [
      \%login_data
    ],
    metadata => {
      reporter => 'spoor.test.capefox.co'
    }
  },
);

App::Spoor::EntryTransmitter::transmit(\%login_data, $ua, \%config);

my $last_request = $ua->last_http_request_sent;

is($last_request->method(), 'POST', 'Posts login data to the api');
is($last_request->uri(), 'http://localhost:3000/api/reports', 'URI is correct');
is($last_request->header('Content-Type'), 'application/json', 'JSON content type');
is($last_request->header('Authorization'), 'Basic ' . encode_base64('user123:secret'), 'Sets basic auth credentials');
is_deeply(from_json($last_request->content()), \%submitted_login_content, 'Submits the login data correctly');

my %forward_added_partial_data = (
  type => 'forward_added_partial',
  foo => 'bar'
);

my %submitted_forward_added_partial_content = (
  report => {
    entries => [
      \%forward_added_partial_data
    ],
    metadata => {
      reporter => 'spoor.test.capefox.co'
    }
  },
);

App::Spoor::EntryTransmitter::transmit(\%forward_added_partial_data, $ua, \%config);

$last_request = $ua->last_http_request_sent;

is($last_request->method(), 'POST', 'Posts forward_added_partial data to the api');
is($last_request->uri(), 'http://localhost:3000/api/reports', 'URI is correct');
is($last_request->header('Content-Type'), 'application/json', 'JSON content type');
is($last_request->header('Authorization'), 'Basic ' . encode_base64('user123:secret'), 'Sets basic auth credentials');
is_deeply(
  from_json($last_request->content()), 
  \%submitted_forward_added_partial_content,
  'Submits the added forward partial data correctly'
);

$ua = Test::LWP::UserAgent->new;
$ua->map_response(qr{reports}, HTTP::Response->new('202', 'OK', [], ''));
ok(
  App::Spoor::EntryTransmitter::transmit(\%forward_added_partial_data, $ua, \%config),
  'Returns true if the response is HTTP 202'
);

$ua = Test::LWP::UserAgent->new;
$ua->map_response(qr{reports}, HTTP::Response->new('500', 'ERROR', [], ''));
ok(
  !App::Spoor::EntryTransmitter::transmit(\%forward_added_partial_data, $ua, \%config),
  'Returns false if the response is not HTTP 202'
);

done_testing();
