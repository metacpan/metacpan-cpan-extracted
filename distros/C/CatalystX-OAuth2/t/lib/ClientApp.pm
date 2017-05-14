package ClientApp;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst' }

use AuthServer;
use Test::WWW::Mechanize::PSGI;

my $client = AuthServer->model('DB::Client')->first;
my $ua = Test::WWW::Mechanize::PSGI->new( app => AuthServer->psgi_app );

__PACKAGE__->config(
  'Plugin::Authentication' => {
    default => {
      credential => {
        class     => 'OAuth2',
        grant_uri => 'http://authserver/request',
        token_uri => 'http://authserver/token',
        client_id => $client->id,
        ua        => $ua
      },
      store => { class => 'Null' }
    }
  }
);

__PACKAGE__->setup(qw(
  ConfigLoader
  Authentication
  Session
  Session::State::Cookie
  Session::Store::Dummy
));

1;
