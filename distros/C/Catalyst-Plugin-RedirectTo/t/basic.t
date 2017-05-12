use Test::Most;

{
  package MyApp::Controller::Example;
  $INC{'MyApp/Controller/Example.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub does_redirect_to_arg :Local {
    my ($self, $c) = @_;
    $c->redirect_to( $self->action_for('target_arg'), [100], {q=>1} );
  }

  sub does_redirect_to_arg302 :Local {
    my ($self, $c) = @_;
    $c->redirect_to( $self->action_for('target_arg'), [100], {q=>1}, \302 );
  }

  sub target_arg :Local Args(1) {
    my ($self, $c, $id) = @_;
    $c->response->content_type('text/plain');
    $c->response->body("This is the target action for $id");
  }

  sub does_redirect_to_noarg :Local {
    my ($self, $c) = @_;
    $c->redirect_to( $self->action_for('target_noarg'));
  }

  sub does_redirect_to_noarg302 :Local {
    my ($self, $c) = @_;
    $c->redirect_to( $self->action_for('target_noarg'), \302);
  }

  sub target_noarg :Local {
    my ($self, $c, $id) = @_;
    $c->response->content_type('text/plain');
    $c->response->body("This is the target action for $id");
  }

  sub does_redirect_to_noarg_action :Local {
    my ($self, $c) = @_;
    $c->redirect_to_action('example/target_noarg');
  }

  package MyApp;
  use Catalyst 'RedirectTo';

  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my $res = request "/example/does_redirect_to_arg";
  ok $res->is_redirect;
  is $res->code, 303, 'OK';
  is $res->header('location'), 'http://localhost/example/target_arg/100?q=1';
}

{
  my $res = request "/example/does_redirect_to_arg302";
  ok $res->is_redirect;
  is $res->code, 302, 'OK';
  is $res->header('location'), 'http://localhost/example/target_arg/100?q=1';
}

{
  my $res = request "/example/does_redirect_to_noarg";
  ok $res->is_redirect;
  is $res->code, 303, 'OK';
  is $res->header('location'), 'http://localhost/example/target_noarg';
}

{
  my $res = request "/example/does_redirect_to_noarg302";
  ok $res->is_redirect;
  is $res->code, 302,'OK';
  is $res->header('location'), 'http://localhost/example/target_noarg';
}

{
  my $res = request "/example/does_redirect_to_noarg_action";
  ok $res->is_redirect;
  is $res->code, 303, 'OK';
  is $res->header('location'), 'http://localhost/example/target_noarg';
}

done_testing;
