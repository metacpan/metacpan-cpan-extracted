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

    Dancer2::Plugin::Auth::Tiny->extend(
      admin => sub {
        my ($dsl, $coderef) = @_;
        return sub {
          if ( $dsl->app->session->read("is_admin") ) {
            goto \&$coderef;
          }
          else {
            return "Access denied";
          }
        };
      }
    );

    set show_errors => 1;
    set session     => 'Simple';

    get '/public' => sub { return 'index' };

    get '/admin' => needs admin => sub { return 'admin' };

    get '/login' => sub {
      session "user"     => "Larry Wall";
      session "is_admin" => 1;
      return "login";
    };

    get '/logout' => sub {
      app->destroy_session;
      redirect uri_for('/public');
    };
}

my $test = Plack::Test->create( App->to_app );
my $url  = 'http://localhost';

subtest 'defaults' => sub {
    {
        my $res = $test->request( HTTP::Request->new( GET => "$url/public" ) );
        like $res->content, qr/index/i, "GET /public works";
    }

    {
        my $res = $test->request( HTTP::Request->new( GET => "$url/admin" ) );
        like $res->content, qr/denied/i, "GET /admin reports denied";
    }
};

subtest 'logging in and logging out' => sub {
    my $jar = HTTP::Cookies->new();

    {
        my $res = $test->request( HTTP::Request->new( GET => "$url/login" ) );
        is $res->content, 'login', 'GET /login';

        $jar->extract_cookies($res);
    }

    {
        my $req = HTTP::Request->new( GET => "$url/admin" );
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        is $res->content, 'admin', 'GET /admin now works';
    }

    {
        my $req = HTTP::Request->new( GET => "$url/logout" );
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        ok $res->is_redirect, 'GET /logout redirects';
        like $res->header('Location'), qr{/public}, 'GET /logout redirects to public';
        like
            $res->content,
            qr{This item has moved},
            'Correct content';

        $jar->extract_cookies($res);
    }

    {
        my $req = HTTP::Request->new( GET => "$url/admin" );
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        like $res->content, qr/denied/i, "GET /admin reports denied again";
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
