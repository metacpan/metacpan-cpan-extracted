use Test::Most;

{  
  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  sub myaction :Chained(/) Does('Methods') PathPart('') CaptureArgs(1) {
    my ($self, $c, $arg) = @_;
    # When this action is matched, first execute this action's
    # body, then an action matching the HTTP method or the not
    # implemented one if needed.
    $c->stash(first=>1);
  }

    sub myaction_GET :Action {
      my ($self, $c, $arg) = @_;
      # Note that if the 'parent' action has args or capture-args, those are
      # made available to a matching method action.
      $c->res->body($c->stash->{first}.'get'.$arg);
    }

    sub myaction_POST {
      my ($self, $c, $arg) = @_;
      $c->res->body($c->stash->{first}.'post'.$arg);
    }

    sub myaction_not_implemented {
      my ($self, $c, $arg) = @_;
      # There's a sane default for this, but you can override as needed.
      $c->res->body($c->stash->{first}.'na'.$arg);
    }

    sub next_action_in_chain :Chained(myaction) PathPart('') Args(0) { }

    sub no_methods_implemented :Chained(/) Does('Methods') PathPart('fail') Args(0) { }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;
  MyApp::Controller::Root->config(namespace=>'');

  package MyApp;
  use Catalyst;
  
  MyApp->setup;
}

use Catalyst::Test 'MyApp';
use HTTP::Request::Common;

{
  ok my $res = request(GET '/22');
  is $res->content, '1get22';
}

{
  ok my $res = request(HEAD '/22');
  is $res->content, '';
}

{
  ok my $res = request(POST '/22');
  is $res->content, '1post22';
}

{
  ok my $res = request(PUT '/22');
  is $res->content, '1na22';
}

{
  ok my $res = request(GET '/fail');
  is $res->code, 405;
  is $res->header( 'Allow' ), '';
}

done_testing;
