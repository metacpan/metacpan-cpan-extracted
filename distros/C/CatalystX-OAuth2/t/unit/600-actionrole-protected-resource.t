use strictures 1;
use Test::More;
use HTTP::Request::Common;
use CatalystX::Test::MockContext;
use lib 't/lib';

my $mock = mock_context('AuthServer');

my $client = AuthServer->model('DB::Client')->first;
my $code = $client->codes->create( { tokens => [ {} ], owner => {} } );

my $token = $code->tokens->first;

{
  my $c = $mock->( GET '/gold' );
  $c->dispatch;
  is_deeply( $c->error, [] );
  is( $c->res->status, 401 );
}

{
  my $c =
    $mock->( GET '/gold', Authorization => 'Bearer ' . $token->as_string );
  $c->dispatch;
  is( $c->req->oauth2->token->as_string, $token->as_string );
  is( $token->owner->id,                 $c->req->oauth2->token->owner->id );
  is_deeply( $c->error, [] );
  is( $c->res->body, 'gold' );
}

done_testing();
