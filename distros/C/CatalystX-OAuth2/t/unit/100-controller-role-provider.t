use strictures 1;
use Test::More;
use Test::Exception;
use Plack::Test;
use HTTP::Request::Common;
use CatalystX::Test::MockContext;

use lib 't/lib';
use AuthServer;

my $ctl = AuthServer->controller('OAuth2::Provider');
lives_ok { $ctl->check_provider_actions };
is( $ctl->_request_auth_action, $ctl->action_for('request') );
is( $ctl->_get_auth_token_via_auth_grant_action, $ctl->action_for('grant') );

package AuthServer::Mock::Controller;
use Moose;

BEGIN { extends 'Catalyst::Controller' }

with 'CatalystX::OAuth2::Controller::Role::Provider';

around check_provider_actions => sub {
  die qq{yo, I'm dead dawg};
};

package main;

{

  my $mock = mock_context('AuthServer');
  my $c    = $mock->( GET '/request' );

  throws_ok {
    AuthServer::Mock::Controller->COMPONENT(
      AuthServer => $c,
      { store => { class => 'DBIC', client_model => 'DB::Cient' } }
    )->register_actions($c);
  }
  qr/yo, I'm dead dawg/,
    'provider actions checked when running register_actions';
}

done_testing();
