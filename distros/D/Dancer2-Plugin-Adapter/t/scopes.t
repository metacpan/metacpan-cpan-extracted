use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use Plack::Test;
use HTTP::Request::Common;

plan skip_all => 'module HTTP::Cookies required'
    unless eval "use HTTP::Cookies; 1";

use File::Temp 0.19; # newdir
use JSON;

{
  package Test::Adapter::Scopes;
  use Dancer2;
  use Dancer2::Plugin::Adapter;

  set show_errors => 1;
  set serializer  => 'JSON';
  set session => 'Simple';

  set plugins => {
    Adapter => {
      singleton_tempdir => {
        class       => 'File::Temp',
        constructor => 'newdir',
        scope       => 'singleton',
      },
      request_tempdir => {
        class       => 'File::Temp',
        constructor => 'newdir',
        scope       => 'request',
      },
      none_tempdir => {
        class       => 'File::Temp',
        constructor => 'newdir',
        scope       => 'none',
      },
    },
  };

  get '/' => sub {
    return {
      singleton    => "" . service("singleton_tempdir"),
      request      => "" . service("request_tempdir"),
      request_copy => "" . service("request_tempdir"),
      fresh        => "" . service("none_tempdir"),
      fresh_copy   => "" . service("none_tempdir"),
    };
  };
}

my $test = Plack::Test->create( Test::Adapter::Scopes->to_app );
my $jar = HTTP::Cookies->new();
my $jar2 = HTTP::Cookies->new();

my $url = 'http://localhost/';

    # first request
    my $first = eval { from_json( test_request($url, $jar)->content ) };
    diag $@ if $@;
    is(
      $first->{request},
      $first->{request_copy},
      "request scope preserved in request"
    );
    isnt( $first->{fresh}, $first->{fresh_copy},
      "no-scope services vary within request" );

    # second request, same session
    my $second = eval { from_json( test_request($url, $jar)->content ) };
    diag $@ if $@;
    is( $first->{singleton}, $second->{singleton},
      "singleton scope preserved across requests" );
    isnt( $first->{request}, $second->{request},
      "request scope varies across requests" );

    # third request, different session
    my $third = eval { from_json( test_request($url, $jar2)->content ) };
    diag $@ if $@;
    is( $first->{singleton}, $third->{singleton},
      "singleton scope preserved across sessions" );

done_testing;

sub test_request {
    my ($url, $jar) = @_;
    my $req = GET($url);
    $jar->add_cookie_header($req);

    my $res = $test->request($req);
    $jar->extract_cookies($res);

    return $res;
}

# COPYRIGHT
