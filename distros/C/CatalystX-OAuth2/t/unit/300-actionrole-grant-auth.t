use strictures 1;
use Test::More;

use HTTP::Request::Common;
use lib 't/lib';
use CatalystX::Test::MockContext;

my $mock = mock_context('AuthServer');

my $code =
  AuthServer->model('DB::Code')
  ->create( { client => { endpoint => '/client/foo' } } );

# try grant with invalid code and no approval param
# should display form
{
  my $uri = URI->new('/grant');
  $uri->query_form(
    { response_type => 'code',
      client_id     => 1,
      state         => 'bar',
      code          => 999999,
      redirect_uri  => '/client/foo',
    }
  );
  $code->discard_changes;
  ok(!$code->is_active);
  my $c = $mock->( GET $uri );
  $c->dispatch;
  is_deeply( $c->error, [], 'dispatches to request action cleanly' );
  is( $c->res->body, undef, q{doesn't produce warning} );
  ok( $c->req->can('oauth2'),
    "installs oauth2 accessors if request is valid" );
  ok( Moose::Util::does_role( $c->req, 'CatalystX::OAuth2::Request' ) );
  my $res    = $c->res;
  my $client = $c->controller->store->find_client(1);
  isa_ok( my $oauth2 = $c->req->oauth2,
    'CatalystX::OAuth2::Request::GrantAuth' );
  my $redirect = $c->req->oauth2->next_action_uri( $c->controller, $c );
  is_deeply(
    { $redirect->query_form },
    { error => 'server_error',
      error_description =>
        'the server encountered an unexpected error condition'
    },
    'prohibits access if the user denies access'
  );
  is( $res->status,   200 ); # should display form
}

# try grant with invalid code and a positive approval param
# should redirect with error
# this case should only ever be triggered if someone tries to circumvent
# the regular authorization flow
{
  my $uri = URI->new('/grant');
  $uri->query_form(
    { response_type => 'code',
      client_id     => 1,
      state         => 'bar',
      code          => 99999,
      redirect_uri  => '/client/foo',
      approved      => 1
    }
  );
  $code->discard_changes;
  ok(!$code->is_active);
  my $c = $mock->( GET $uri );
  $c->dispatch;
  is_deeply( $c->error, [], 'dispatches to request action cleanly' );
  is( $c->res->body, undef, q{doesn't produce warning} );
  ok( $c->req->can('oauth2'),
    "installs oauth2 accessors if request is valid" );
  ok( Moose::Util::does_role( $c->req, 'CatalystX::OAuth2::Request' ) );
  my $res    = $c->res;
  my $client = $c->controller->store->find_client(1);
  isa_ok( my $oauth2 = $c->req->oauth2,
    'CatalystX::OAuth2::Request::GrantAuth' );
  my $redirect = $c->req->oauth2->next_action_uri( $c->controller, $c );
  is_deeply(
    { $redirect->query_form },
    { error => 'server_error',
      error_description =>
        'the server encountered an unexpected error condition'
    },
    'error if presented an invalid code'
  );
  is( $res->location, $redirect );
  is( $res->status,   302 );
}

# try a grant with a valid code and no approval parameter
# should display form
{
  my $uri = URI->new('/grant');
  $uri->query_form(
    { response_type => 'code',
      client_id     => 1,
      state         => 'bar',
      redirect_uri  => '/client/foo',
      code          => $code->as_string,
    }
  );
  $code->discard_changes;
  ok(!$code->is_active);
  my $c = $mock->( GET $uri );
  $c->dispatch;
  is_deeply( $c->error, [], 'dispatches to request action cleanly' );
  is( $c->res->body, undef, q{doesn't produce warning} );
  ok( $c->req->can('oauth2'),
    "installs oauth2 accessors if request is valid" );
  ok( Moose::Util::does_role( $c->req, 'CatalystX::OAuth2::Request' ) );
  my $res    = $c->res;
  my $client = $c->controller->store->find_client(1);
  isa_ok( my $oauth2 = $c->req->oauth2,
    'CatalystX::OAuth2::Request::GrantAuth' );
  ok( !$res->location );
  is( $res->status, 200 );
}

# try a grant with a valid code and denied approval
# should redirect with access_denied
{
  my $uri = URI->new('/grant');
  $uri->query_form(
    { response_type => 'code',
      client_id     => 1,
      state         => 'bar',
      redirect_uri  => '/client/foo',
      code          => $code->as_string,
      approved      => 0
    }
  );
  $code->discard_changes;
  ok(!$code->is_active);
  my $c = $mock->( GET $uri );
  $c->dispatch;
  is_deeply( $c->error, [], 'dispatches to request action cleanly' );
  is( $c->res->body, undef, q{doesn't produce warning} );
  ok( $c->req->can('oauth2'),
    "installs oauth2 accessors if request is valid" );
  ok( Moose::Util::does_role( $c->req, 'CatalystX::OAuth2::Request' ) );
  my $res    = $c->res;
  my $client = $c->controller->store->find_client(1);
  isa_ok( my $oauth2 = $c->req->oauth2,
    'CatalystX::OAuth2::Request::GrantAuth' );
  my $redirect = $c->req->oauth2->next_action_uri( $c->controller, $c );
  is_deeply(
    { $redirect->query_form },
    { error => 'access_denied',
      error_description =>
        'the resource owner denied the request'
    },
    "deny access if user didn't approve"
  );
  is( $res->location, $redirect );
  is( $res->status,   302 );
}

# try a grant with a valid code and approval
# should activate code and redirect
{
  my $uri = URI->new('/grant');
  $uri->query_form(
    { response_type  => 'code',
      client_id      => 1,
      state          => 'bar',
      redirect_uri   => '/client/foo',
      code           => $code->as_string,
      approved       => 1
    }
  );
  $code->discard_changes;
  ok(!$code->is_active);
  my $c = $mock->( GET $uri );
  $c->dispatch;
  is_deeply( $c->error, [], 'dispatches to request action cleanly' );
  is( $c->res->body, undef, q{doesn't produce warning} );
  ok( $c->req->can('oauth2'),
    "installs oauth2 accessors if request is valid" );
  ok( Moose::Util::does_role( $c->req, 'CatalystX::OAuth2::Request' ) );
  my $res    = $c->res;
  my $client = $c->controller->store->find_client(1);
  isa_ok( my $oauth2 = $c->req->oauth2,
    'CatalystX::OAuth2::Request::GrantAuth' );
  my $redirect = $c->req->oauth2->next_action_uri( $c->controller, $c );
  is_deeply( { $redirect->query_form },
    { code => $code->as_string, state => 'bar' } );
  is( $res->location, $redirect );
  is( $res->status,   302 );
  $code->discard_changes;
  ok($code->is_active);
}

done_testing();
