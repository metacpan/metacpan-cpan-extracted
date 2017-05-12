package t::Util;
use strictures 1;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use Redis;

my $jar = HTTP::Cookies->new;

############################################################################
# Setup environment for Delti::WheelShop testing environment.

sub setenv {
  $ENV{PLACK_ENV} = $ENV{DANCER_ENVIRONMENT} = 'testing';
  $ENV{DANCER_SESSION_REDIS_TEST_MOCK} = 1;
}

############################################################################
# Setup environment for Delti::WheelShop testing environment.

sub setconf {
  my ($set) = @_;
  $set->( environment => 'testing' );
  $set->( warnings    => 1 );
  $set->( traces      => 1 );
  $set->( logger      => 'null' );
  $set->( show_errors => 1 );
  # config ignored when using mocked test server
  $set->(
    engines => {
      session => {
        Redis => $ENV{DANCER_SESSION_REDIS_TEST_MOCK}
            ? { redis_test_mock => 1 }
            : {
          cookie_name         => 'vm',
          redis_server        => "localhost:6379",
          session_duration => 600,
          redis_serialization => {
            module      => "Dancer2::Session::Redis::Serialization::Sereal",
            compression => "snappy",
          }
        }
      }
    }
  );
  $set->( session => 'Redis' );
  if ( $ENV{DANCER_SESSION_REDIS_TEST_MOCK} ) {
    return 1;
  }
  else {
    my $res = eval {
      my $redis = Redis->new(
        server => 'localhost:6379',
        name   => 'dancer2_session_redis_test',
      );
      $redis->set(testing => 123);
      $redis->get('testing');
    };
    return $res && $res == 123 ? 1 : 0;
  }
}

############################################################################

sub psgi_request_ok {
  my ( $app, $method, $uri, $expected_response ) = @_;
  my $client = sub {
    my ($cb) = @_;
    my $req = HTTP::Request->new( $method => "http://localhost$uri" );
    $jar->add_cookie_header($req);
    my $res = $cb->($req);
    $jar->extract_cookies($res);
    subtest "$method $uri" => sub {
      plan tests => $expected_response ? 2 : 1;
      ok( $res->is_success, "request successful for $method $uri" );
      like( $res->decoded_content, $expected_response, "expected response content for $method $uri" )
        if $expected_response;
    };
    return;
  };
  test_psgi( $app, $client );
  return;
}
sub psgi_change_session_id {
  my $app = shift;
  my $client = sub {
    my ($cb) = @_;
    my ( $sid1, $sid2 );
    $jar->scan( sub { $sid1 = $_[2] } );
    my $req = HTTP::Request->new( GET => "http://localhost/change_session_id" );
    $jar->add_cookie_header($req);
    my $res = $cb->($req);
    $jar->extract_cookies($res);
    $jar->scan( sub { $sid2 = $_[2] } );
    subtest "change_session_id" => sub {
      plan tests => 2;
      ok( $res->is_success, "request successful for /change_session_id" );
      SKIP: {
        skip "change_session_id not supported by this Dancer2 version", 1
          if $res->content eq 'unsupported';
          isnt $sid1, $sid2, "Session ID has changed";
      };
    };
    return;
  };
  test_psgi( $app, $client );
  return;
}

############################################################################
1;
