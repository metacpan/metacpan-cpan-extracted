use strictures 1;
use Test::More;
use JSON::Any;
use HTTP::Request::Common;
use lib 't/lib';
use CatalystX::Test::MockContext;

my $json = JSON::Any->new;
my $mock = mock_context('AuthServer');

my $code = AuthServer->model('DB::Code')
  ->create( { client => { endpoint => '/client/foo' } } );

{
  my $uri = URI->new('/token');
  $uri->query_form(
    { grant_type   => 'authorization_code',
      redirect_uri => '/client/foo',
      code         => $code->as_string
    }
  );
  my $c = $mock->( GET $uri );
  $c->dispatch;
  is_deeply( $c->error, [] );
  my $res = $c->res;
  is_deeply(
    $json->jsonToObj( $res->body ),
    { access_token => 1,
      token_type   => 'bearer',
      expires_in   => 3600
    }
  );
  is( $res->status, 200 );
}

done_testing();
