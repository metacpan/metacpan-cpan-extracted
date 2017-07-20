use strictures 1;
use Test::More;
use HTTP::Request::Common;
use HTTP::Request;
use lib 't/lib';
use Catalyst::Test 'AuthServer';

my $client = AuthServer->model('DB::Client')->first;
my $code = $client->codes->create( { tokens => [ {} ], owner => {} } );

my $token = $code->tokens->first;

{
  my ($res2, $c) = ctx_request('/gold');
  $c->dispatch;
  is_deeply( $c->error, [] );
  is( $c->res->status, 401 );
}

{
  my $request = HTTP::Request->new(GET => '/gold', [Authorization => 'Bearer ' . $token->as_string]);
  my ($res2, $c) = ctx_request($request);

  $c->dispatch;
  is( $c->req->oauth2->token->as_string, $token->as_string );
  is( $token->owner->id,                 $c->req->oauth2->token->owner->id );
  is_deeply( $c->error, [] );
  is( $c->res->body, 'gold' );
}

done_testing();
