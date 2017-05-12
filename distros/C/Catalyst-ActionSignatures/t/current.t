use Test::Most;

{
  package MyApp::Model::ReturnsTrue;
  $INC{'MyApp/Model/ReturnsTrue.pm'} = __FILE__;

  use Moose;
  extends 'Catalyst::Model';

  sub ACCEPT_CONTEXT {
    my ($self, $c) = @_;
    if(my @args = @{ $c->req->args||[] }) {
      return $args[0];
    } else {
      return 200;
    }
  }
  
  package MyApp::Controller::Root;

  use Moose;
  use MooseX::MethodAttributes;
  use Catalyst::ActionSignatures;

  extends 'Catalyst::Controller';

  sub default_model($res,Model $model) :Local {
    $res->body($model)
  }

  sub chainroot :Chained(/) PathPrefix CaptureArgs(0) {
    my ($self, $ctx) = @_;
    $ctx->stash(current_model_instance => 100);
  }

    sub notfound :Chained(chainroot) PathPart('') Args  { $_[1]->res->body('notfound') }


    sub default_again($res,Model $model required) :Chained(chainroot/) {
      return $res->body($model);
    }

    sub default_again_arg($res, Arg $id isa '"Int"', Model $model required) :Chained(chainroot/) {
      return $res->body($model);
    }

    MyApp::Controller::Root->config(namespace=>'');

  package MyApp;
  use Catalyst;
  
  MyApp->config(default_model=>'ReturnsTrue');
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request('/default_model');
  is $res->content, '200';
}

{
  my ($res, $c) = ctx_request('/default_again');
  is $res->content, '200';
}

{
  my ($res, $c) = ctx_request('/default_again_arg/300');
  is $res->content, '300';
}

{
  my ($res, $c) = ctx_request('/default_again_arg/john');
  is $res->content, 'notfound';
}

done_testing;
