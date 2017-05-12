use strict;
use warnings;
use utf8;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't';
}

use Test::More;
use HTTP::Cookies;
use HTTP::Request::Common;
use JSON::MaybeXS;
use Plack::Builder;
use Plack::Test;

{
    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::PageHistory;

    set session => 'Simple';

    get '/**' => sub {
        content_type('application/json');
        my $page = history->latest_page;

        return to_json(
            {
                path         => $page->path,
                query_string => $page->query_string,
                request_path => $page->request_path,
                uri          => $page->uri,
                request_uri  => $page->request_uri,
            }
        );
    };
}

subtest '... app mounted at /' => sub {
    my $app = TestApp->to_app;

    ok ref($app) eq 'CODE', "Got an app";
    my $test = Plack::Test->create($app);

    my $req = GET "http://localhost/my/path?foo=הלו";
    my $res = $test->request($req);
    ok( $res->is_success, "get /my/path OK" );

    # הלו gets url encoded to %D7%94%D7%9C%D7%95
    is_deeply decode_json( $res->content ),
      {
        path         => '/my/path',
        query_string => 'foo=%D7%94%D7%9C%D7%95',
        request_path => '/my/path',
        uri          => '/my/path?foo=%D7%94%D7%9C%D7%95',
        request_uri  => '/my/path?foo=%D7%94%D7%9C%D7%95',
      },
      "Check PageHistory is OK";
};

subtest '... app mounted at /' => sub {
    my $app = builder {
        mount '/bar/' => TestApp->to_app;
    };

    ok ref($app) eq 'CODE', "Got an app";
    my $test = Plack::Test->create($app);

    my $req = GET "http://localhost/bar/my/path?foo=הלו";
    my $res = $test->request($req);
    ok( $res->is_success, "get /bar/my/path OK" );

    is_deeply decode_json( $res->content ),
      {
        path         => '/my/path',
        query_string => 'foo=%D7%94%D7%9C%D7%95',
        request_path => '/bar/my/path',
        uri          => '/my/path?foo=%D7%94%D7%9C%D7%95',
        request_uri  => '/bar/my/path?foo=%D7%94%D7%9C%D7%95',
      },
      "Check PageHistory is OK";
};

done_testing;
