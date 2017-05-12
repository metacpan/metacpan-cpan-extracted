use strict;
use warnings;
use Test::More 0.96;
use File::Temp 0.19; # newdir
use Plack::Test;
use HTTP::Cookies;
use HTTP::Request;

{
    package App;

    use Dancer2;
    use Dancer2::Plugin::Auth::Tiny;

    set show_errors => 1;
    set session     => 'Simple';

    get '/public' => sub { return 'index' };

    any [qw/get post/] => '/private' => needs login =>
      sub { return "params: " . join( ":", params ) };

    get '/login' => sub {
      session "user" => params->{user};
      redirect params->{return_url}, 303;
    };

    get '/logout' => sub {
      app->destroy_session;
      redirect uri_for('/public');
    };
}

my $test = Plack::Test->create( App->to_app );
my $url  = "http://localhost";

subtest 'defaults' => sub {
    my $res = $test->request( HTTP::Request->new( GET => "$url/public" ) );
    like $res->content, qr/index/i, "GET /public works";
};

use HTTP::Request::Common;
subtest 'login with post' => sub {
    my $jar = HTTP::Cookies->new();
    my $redir_url;

    {
        my $req = POST '/private', { foo => 'bar', user => 'Larry' };
        my $res = $test->request($req);

        ok $res->is_redirect, '/private redirects';
        like $res->header('Location'), qr{/login}, 'POST /private redirects to /login';
        like
            $res->content,
            qr{This item has moved},
            'Correct content';

        $redir_url = $res->header('Location');
    }

    {
        my $res = $test->request( GET $redir_url );

        ok $res->is_redirect, '/login redirects';
        like $res->header('Location'), qr{/private}, '/login redirects back to /private';

        $redir_url = $res->header('Location');
        $jar->extract_cookies($res);
    }

    {
        my $req = GET $redir_url;
        $jar->add_cookie_header($req);

        my $res = $test->request($req);

        like $res->content, qr/params:\s*$/i,
          "POST /private doesn't leak post params in redirect"
            or diag explain $res;
    }

    {
        my $req = POST "$url/private", { foo => 'bar' };
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        like $res->content, qr/params: foo:bar/i,
          "POST /private after login has parameters";
    }
};

done_testing;
#
# This file is part of Dancer2-Plugin-Auth-Tiny
#
# This software is Copyright (c) 2016 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
