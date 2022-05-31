use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
};

use Test::More;

use lib "t/lib";

use MiniUA;

#try completely random cookie unknown for our application; should be rejected
my $cookie_name = 'sessiontestapp_session';
my $cookie_value = '89c3a019866af6f5a305e10189fbb23df3f4772c';
my ( @injected_cookie ) = ( 1, $cookie_name , $cookie_value ,'/', undef, 0, undef, undef, undef, {} );
my $injected_cookie_str = "${cookie_name}=${cookie_value}";

my $ua1 = MiniUA->new('SessionTestApp');
$ua1->cookie_jar->set_cookie( @injected_cookie );

my $res = $ua1->get( "http://localhost/login" );
my $cookie1 = $res->header('Set-Cookie');

ok $cookie1, "Set-Cookie 1";
isnt $cookie1, qr/$injected_cookie_str/, "Logging in generates us a new cookie";

$res = $ua1->get( "http://localhost/get_sessid" );
my $sid1 = $res->content;

#set session variable var1 before session id change
$ua1->get( "http://localhost/set_session_variable/var1/set_before_change");
$res = $ua1->get( "http://localhost/get_session_variable/var1");
is +$res->content, 'VAR_var1=set_before_change';

#just diagnostic dump
#diag "Before-change:".$ua1->get( "http://localhost/dump_session" )->content;

#change session id; all session data should be kept; old session id invalidated
$res = $ua1->get( "http://localhost/change_sessid" );
my $cookie2 = $res->header('Set-Cookie');

ok $cookie2, "Set-Cookie 2";
isnt $cookie2, $cookie1, "Cookie changed";

$res = $ua1->get( "http://localhost/get_sessid" );
my $sid2 = $res->content;
isnt $sid2, $sid1, 'SID changed';

#just diagnostic dump
#diag "After-change:".$ua1->get( "http://localhost/dump_session" )->content;

#set session variable var2 after session id change
$ua1->get( "http://localhost/set_session_variable/var2/set_after_change");

#check if var1 and var2 contain expected values
$res = $ua1->get( "http://localhost/get_session_variable/var1");
is +$res->content, 'VAR_var1=set_before_change';
$res = $ua1->get( "http://localhost/get_session_variable/var2");
is +$res->content, 'VAR_var2=set_after_change';

#just diagnostic dump
#diag "End1".$ua1->get( "http://localhost/dump_session" )->content;

#try to use old cookie value (before session_id_change)
my $ua2 = MiniUA->new('SessionTestApp');
$ua2->cookie_jar->set_cookie( @injected_cookie );

#if we take old cookie we should not be able to get any old session data
$res = $ua2->get( "http://localhost/get_session_variable/var1");
is +$res->content, 'VAR_var1=n.a.';
$res = $ua2->get( "http://localhost/get_session_variable/var2");
is +$res->content, 'VAR_var2=n.a.';

#just diagnostic dump
#diag "End2".$ua1->get( "http://localhost/dump_session" )->content;

done_testing;
