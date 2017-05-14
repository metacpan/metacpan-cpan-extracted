use strictures 1;
use Test::More;
use Test::MockObject;
use CatalystX::Test::MockContext;
use HTTP::Request::Common;
use JSON::Any;
use lib 't/lib';
use AuthServer;
use ClientApp;

use Catalyst::Authentication::Credential::OAuth2;

# can't use Test::Mock::Object here because mocked methods aren't recognized
# by the requires 'method'; role application constraint
package Test::Mock::Store;
use Moose;

sub for_session { }

package Test::Mock::Realm;
use Moose;
use URI;
our $user;
our $store = Test::Mock::Store->new;
our @called;
sub find_user    { push @called, [ 'find_user',    [@_] ]; $user }
sub restore_user { push @called, [ 'restore_user', [@_] ]; $user }
sub persist_user { push @called, [ 'persist_user', [@_] ]; $user }
sub store        { push @called, [ 'store',        [@_] ]; $store }

package main;

my $mock = mock_context('ClientApp');

{
  my $c     = $mock->( GET '/' );
  my $realm = Test::Mock::Realm->new;
  my $cred  = Catalyst::Authentication::Credential::OAuth2->new(
    { grant_uri     => 'http://server.foo/grant',
      token_uri     => 'http://server.foo/token',
      client_id     => 42,
      client_secret => 'foosecret'
    },
    ClientApp => $realm
  );
  is_deeply( [ map { $_->name } $realm->meta->calculate_all_roles ],
    [qw(CatalystX::OAuth2::ClientInjector)] );

  ok( !$cred->authenticate( $c, $realm, {} ) );

  # we should have called ->store at this point
  is( @Test::Mock::Realm::called + 0, 1 );
  {
    my ( $name, $args ) = @{ pop @Test::Mock::Realm::called };
    is($name => 'store');
    is_deeply($args, [$realm])
  }
  is( $c->res->status, 302 );

  my $callback_uri = $cred->_build_callback_uri($c);
  is( $callback_uri, 'http://localhost/' );

  my $extend_perms_uri = $cred->extend_permissions($callback_uri);

  # We make the stringy redirect into a URL object to compare
  # since the query part can be ordered variously (did this to
  # solve a failure case when the query keywords were ordered 
  # differently but in real life they are equal by the definitation of
  # URL equality.

  my $redirect_url = URI->new($c->res->redirect);
  is $redirect_url->scheme, $extend_perms_uri->scheme;
  is $redirect_url->path, $extend_perms_uri->path;
  is $redirect_url->authority, $extend_perms_uri->authority;
  is_deeply(
    +{$redirect_url->query_form},
    +{$extend_perms_uri->query_form} );
}

my $j = JSON::Any->new;

{
  my $ua       = Test::MockObject->new;
  my $res      = Test::MockObject->new;
  my $tok_data = {
    access_token  => '2YotnFZFEjr1zCsicMWpAA',
    token_type    => "bearer",
    expires_in    => 3600,
    refresh_token => "tGzv3JOkF0XG5Qx2TlKWIA"
  };
  $res->set_true('is_success');
  $res->mock(
    decoded_content => sub {
      $j->objToJson($tok_data);
    }
  );
  $ua->mock( get => sub {$res} );
  my $uri = URI->new('/');
  $uri->query_form( { code => 'foocode' } );
  my $c    = $mock->( GET $uri );
  my $user = Test::MockObject->new;
  $user->mock( for_session => sub { { foo => 'bar' } } );
  my $realm = Test::Mock::Realm->new;
  $Test::Mock::Realm::user = $user;
  my $cred = Catalyst::Authentication::Credential::OAuth2->new(
    { grant_uri     => 'http://server.foo',
      token_uri     => 'http://server.foo/token',
      client_id     => 42,
      client_secret => 'foosecret',
      ua            => $ua
    },
    ClientApp => $realm
  );
  is_deeply( [ map { $_->name } $realm->meta->calculate_all_roles ],
    [qw(CatalystX::OAuth2::ClientInjector)] );

  ok( my $oauth2_user = $cred->authenticate( $c, $realm, {} ) );
  is_deeply( [ map { $_->name } $user->meta->calculate_all_roles ],
    [qw(CatalystX::OAuth2::ClientContainer)] );
  isa_ok( $oauth2_user->oauth2, 'CatalystX::OAuth2::Client' );
  is( $oauth2_user->oauth2->token, $tok_data->{access_token} );

  {
    my ( $name, $args ) = @{ shift @Test::Mock::Realm::called };
    is( $name, 'store' );
    shift @$args;    # remove $self
    is_deeply( $args, [] );
    is( @Test::Mock::Realm::called + 0, 1 );
  }

  {
    my ( $name, $args ) = @{ shift @Test::Mock::Realm::called };
    is( $name, 'find_user' );
    shift @$args;    # remove $self
    is_deeply( $args, [ { token => $tok_data->{access_token} }, $c ] );
    is( @Test::Mock::Realm::called + 0, 0 );
  }

}

done_testing();
