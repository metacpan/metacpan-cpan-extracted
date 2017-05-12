#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";

use Test::More;

BEGIN {
    eval {
        require Catalyst::Plugin::Session::State::Cookie;
        Catalyst::Plugin::Session::State::Cookie->VERSION(0.03);
    } or plan skip_all => "Catalyst::Plugin::Session::State::Cookie 0.03 or higher is required for this test";
    
    eval { require Test::WWW::Mechanize::Catalyst }
        or plan skip_all => "Test::WWW::Mechanize::Catalyst is required for this test";

    plan tests => 2;
}

use Test::WWW::Mechanize::Catalyst "TestApp";

{
    my $m = Test::WWW::Mechanize::Catalyst->new( cookie_jar => undef );

    $m->post_ok("http://localhost/uri/body_param", { body_param=>'value' }, "post request");
    $m->content_contains( "http://localhost/foo/bar?param=value", "param in body" );

}
