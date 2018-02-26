#!/usr/bin/env perl

use strict;
use warnings;

use Test::More import => ["!pass"];

use Test::Requires {
    'Plack'   => '1.0029',
};

use Plack::Test;
use HTTP::Cookies;
use HTTP::Request::Common;

{
    package MyApp;
    use Dancer ':tests', ':syntax';

    set apphandler  => 'PSGI';
    set appdir      => '';          # quiet warnings not having an appdir
    set access_log  => 0;           # quiet startup banner

    set session_cookie_key  => "John has a long mustache";
    set session             => "cookie";

    hook before => sub {
        if ( !session('uid')
            && request->path_info !~ m{^/login}
        ) {
            return redirect '/login/';
        }
    };

    get '/logout/?' => sub {
        session 'uid'     => undef;
        session->destroy;
        return redirect '/';
    };

    any '/login/?' => sub {
        return redirect '/' if session('uid');

        return 'ok' if session('login');
        session 'login' => undef;
        return 'login page';
    };
}

my $app = Plack::Test->create( MyApp->dance );
my $jar = HTTP::Cookies->new();
my $url = 'http://localhost';
my $redir_url;

{
    my $res = $app->request( HTTP::Request::Common::GET("$url/") );
    ok( $res->is_redirect, 'GET / redirects' );
    is(
        $redir_url = $res->header('Location'),
        'http://localhost/login/',
        'Redirects to /login/',
    );

    $jar->extract_cookies($res);
}

{
    my $req = HTTP::Request::Common::GET($redir_url);
    $jar->add_cookie_header($req);

    my $res = $app->request($req);
    ok( $res->is_success, 'GET / successful' );
    is( $res->content, 'login page', 'Correct login page content' );
}

done_testing;
