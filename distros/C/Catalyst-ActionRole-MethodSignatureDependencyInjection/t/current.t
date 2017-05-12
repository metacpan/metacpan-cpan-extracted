use Test::Most;

{
  package MyApp::Model::ReturnsTrue;
  $INC{'MyApp/Model/ReturnsTrue.pm'} = __FILE__;

  use Moose;
  extends 'Catalyst::Model';

  sub ACCEPT_CONTEXT { return 200  }
  
  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  no warnings::illegalproto;

  sub default_model($res,Model) :Local 
   :Does(MethodSignatureDependencyInjection) UsePrototype(1)
  {
    my ($self, $res, $model) = @_;
    $res->body($model)
  }

  sub chainroot :Chained(/) PathPrefix CaptureArgs(0) {
    my ($self, $ctx) = @_;
    $ctx->stash(current_model_instance => 100);
  }

    sub default_again($res,Model required) :Chained(chainroot)
     :Does(MethodSignatureDependencyInjection) UsePrototype(1)
    {
      my ($self, $res, $model) = @_;
      return $res->body($model);
    }

  package MyApp;
  use Catalyst;
  
  MyApp->config(default_model=>'ReturnsTrue');
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request('/root/default_model');
  is $res->content, '200';
}

{
  my ($res, $c) = ctx_request('/root/default_again');
  is $res->content, '200';
}

done_testing;
