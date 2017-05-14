#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    eval { require Catalyst::Plugin::Session::State::Cookie; Catalyst::Plugin::Session::State::Cookie->VERSION(0.03) }
      or plan skip_all =>
      "Catalyst::Plugin::Session::State::Cookie 0.03 or higher is required for this test";

    eval {
        require Test::WWW::Mechanize::Catalyst;
        Test::WWW::Mechanize::Catalyst->VERSION(0.51);
    }
    or plan skip_all =>
        'Test::WWW::Mechanize::Catalyst >= 0.51 is required for this test';

    plan tests => 10;
}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

#try completely random cookie unknown for our application; should be rejected
my $cookie_name = 'sessiontestapp_session';
my $cookie_value = '89c3a019866af6f5a305e10189fbb23df3f4772c';
my ( @injected_cookie ) = ( 1, $cookie_name , $cookie_value ,'/', undef, 0, undef, undef, undef, {} );
my $injected_cookie_str = "${cookie_name}=${cookie_value}";

my $ua1 = Test::WWW::Mechanize::Catalyst->new;
$ua1->cookie_jar->set_cookie( @injected_cookie );

my $res = $ua1->get( "http://localhost/login" );
my $cookie1 = $res->header('Set-Cookie');

ok $cookie1, "Set-Cookie 1";
isnt $cookie1, qr/$injected_cookie_str/, "Logging in generates us a new cookie";

$ua1->get( "http://localhost/get_sessid" );
my $sid1 = $ua1->content;

#set session variable var1 before session id change
$ua1->get( "http://localhost/set_session_variable/var1/set_before_change");
$ua1->get( "http://localhost/get_session_variable/var1");
$ua1->content_is("VAR_var1=set_before_change");

#just diagnostic dump
$ua1->get( "http://localhost/dump_session" );
#diag "Before-change:".$ua1->content;

#change session id; all session data should be kept; old session id invalidated
my $res2 = $ua1->get( "http://localhost/change_sessid" );
my $cookie2 = $res2->header('Set-Cookie');

ok $cookie2, "Set-Cookie 2";
isnt $cookie2, $cookie1, "Cookie changed";

$ua1->get( "http://localhost/get_sessid" );
my $sid2 = $ua1->content;
isnt $sid2, $sid1, 'SID changed';

#just diagnostic dump
$ua1->get( "http://localhost/dump_session" );
#diag "After-change:".$ua1->content;

#set session variable var2 after session id change
$ua1->get( "http://localhost/set_session_variable/var2/set_after_change");

#check if var1 and var2 contain expected values
$ua1->get( "http://localhost/get_session_variable/var1");
$ua1->content_is("VAR_var1=set_before_change");
$ua1->get( "http://localhost/get_session_variable/var2");
$ua1->content_is("VAR_var2=set_after_change");

#just diagnostic dump
$ua1->get( "http://localhost/dump_session" );
#diag "End1:".$ua1->content;

#try to use old cookie value (before session_id_change)
my $ua2 = Test::WWW::Mechanize::Catalyst->new;
$ua2->cookie_jar->set_cookie( @injected_cookie );

#if we take old cookie we should not be able to get any old session data
$ua2->get( "http://localhost/get_session_variable/var1");
$ua2->content_is("VAR_var1=n.a.");
$ua2->get( "http://localhost/get_session_variable/var2");
$ua2->content_is("VAR_var2=n.a.");

#just diagnostic dump
$ua2->get( "http://localhost/dump_session" );
#diag "End2:".$ua2->content;
