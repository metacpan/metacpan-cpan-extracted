use Test::Most;

{
  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  sub create_session :Local {
    my ($self, $c) = @_;
    $c->session(aaa => 111, bbb => 222);
    $c->res->body("create_session");
  }

  sub check_session1 :Local {
    my ($self, $c) = @_;
    Test::Most::is($c->session->{aaa}, 111, 'Session stored expected value');
    Test::Most::is($c->session->{bbb}, 222, 'Session stored expected value');
    $c->res->body("check_session1");
  }

  sub delete_session_key :Local {
    my ($self, $c) = @_;
    delete $c->session->{bbb};
    $c->res->body("delete_session_key");
  }

  sub check_session2 :Local {
    my ($self, $c) = @_;
    Test::Most::is($c->session->{aaa}, 111, 'Session stored expected value');
    Test::Most::is($c->session->{bbb}, undef, 'Session stored expected value');
    $c->res->body("check_session2");
  }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  package MyApp;
  use Catalyst qw/
    Session
    Session::State::Cookie
    Session::Store::Cookie/;

  MyApp->config('Plugin::Session' => {storage_secret_key => 'abc123'});
  MyApp->setup;
}


use HTTP::Request::Common;
use Test::WWW::Mechanize::Catalyst qw/MyApp/;
 
ok my $m = Test::WWW::Mechanize::Catalyst->new;

$m->get_ok( "http://localhost/root/create_session", "create session" );
$m->content_contains("create_session", "Correct content");
$m->get_ok( "http://localhost/root/check_session1", "check session" );
$m->content_contains("check_session1", "Correct content");
$m->get_ok( "http://localhost/root/check_session1", "check session" );
$m->content_contains("check_session1", "Correct content");

$m->get_ok( "http://localhost/root/delete_session_key", "check session" );
$m->content_contains("delete_session_key", "Correct content");
$m->get_ok( "http://localhost/root/check_session2", "check session" );
$m->content_contains("check_session2", "Correct content");

done_testing;
