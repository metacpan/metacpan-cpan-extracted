use Test::Most;

{
  package MyApp::Controller::Example;
  $INC{'MyApp/Controller/Example.pm'} = __FILE__;

  use base 'Catalyst::Controller';
  use HTTP::Request::Common;
   
  sub as_http_request :Local {
    my ($self, $c) = @_;
    $c->redispatch_to(GET $c->uri_for($self->action_for('target')));
  }

  sub as_spec :Local {
    my ($self, $c) = @_;
    $c->redispatch_to(GET => $c->uri_for($self->action_for('target')));
  }

  sub as_action :Local {
    my ($self, $c) = @_;
    $c->redispatch_to($self->action_for('target'));
  }

  sub as_action_args :Local {
    my ($self, $c) = @_;
    $c->redispatch_to($self->action_for('target_with_arg'), 111);
  }

  sub target :Local {
    my ($self, $c) = @_;
    $c->response->content_type('text/plain');
    $c->response->body("This is the target action");
  }

  sub target_with_arg :Local Arg(1) {
    my ($self, $c, $arg) = @_;
    $c->response->content_type('text/plain');
    $c->response->body("This is the target action with args: $arg");
  }


  package MyApp;
  use Catalyst 'ResponseFrom';

  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my $res = request "/example/as_http_request";
  is $res->code, 200, 'OK';
  is $res->content, 'This is the target action', 'correct body';
}

{
  my $res = request "/example/as_spec";
  is $res->code, 200, 'OK';
  is $res->content, 'This is the target action', 'correct body';
}

{
  my $res = request "/example/as_action";
  is $res->code, 200, 'OK';
  is $res->content, 'This is the target action', 'correct body';
}

{
  my $res = request "/example/as_action_args";
  is $res->code, 200, 'OK';
  is $res->content, 'This is the target action with args: 111', 'correct body';
}

done_testing;
