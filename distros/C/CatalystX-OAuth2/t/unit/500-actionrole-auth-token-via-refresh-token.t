use strictures 1;
use Test::More;
use JSON::Any;
use HTTP::Request::Common;
use lib 't/lib';
use CatalystX::Test::MockContext;

my $json = JSON::Any->new;
my $mock = mock_context('AuthServer');

my $code = AuthServer->model('DB::Code')->create(
  { client    => { endpoint => '/client/foo' },
    is_active => 1
  }
);

my $refresh;

{
  my $uri = URI->new('/withrefresh/token');
  $uri->query_form(
    { grant_type   => 'authorization_code',
      redirect_uri => '/client/foo',
      code         => $code->as_string
    }
  );
  my $c = $mock->( GET $uri );
  $c->dispatch;
  $c->log->_flush;
  is_deeply( $c->error, [] );
  my $res = $c->res;
  is_deeply(
    $json->jsonToObj( $res->body ),
    { access_token  => 1,
      token_type    => 'bearer',
      expires_in    => 3600,
      refresh_token => 2
    }
  );

  is( $res->status, 200 );
}

{
  my $refresh = AuthServer->model('DB::RefreshToken')->find(2);

  my $uri = URI->new('/refresh');
  $uri->query_form(
    { grant_type    => 'refresh_token',
      refresh_token => $refresh->as_string,
      redirect_uri  => '/client/foo'
    }
  );
  my $c = $mock->( GET $uri );
  $c->dispatch;
  is_deeply( $c->error, [] );
  my $res = $c->res;
  my $obj = $json->jsonToObj( $res->body );
  ok( defined( $refresh->to_access_token ) );
  ok( !$refresh->is_active );
  is_deeply(
    $obj,
    { access_token => $refresh->to_access_token->as_string,
      token_type   => 'bearer',
      expires_in   => 3600
    }
  );
  is( $res->status, 200 );
}

done_testing();
