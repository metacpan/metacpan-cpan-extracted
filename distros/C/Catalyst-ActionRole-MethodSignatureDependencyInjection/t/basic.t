use Test::Most;

{
  package MyApp::Model::A;

  use Moose;
  extends 'Catalyst::Model';

  has aaa => (is=>'ro', required=>1);
  
  sub foo { 'foo' }

  sub COMPONENT {
    my ($class, $app, $args) = @_;
    $args = $class->merge_config_hashes($class->config, $args);
    $args->{model_z} = $app->model('Z');
    return $class->new($app, $args);
  }

  $INC{'MyApp/Model/A.pm'} = __FILE__;

  package MyApp::Model::Z;

  use Moose;
  extends 'Catalyst::Model';

  has zzz => (is=>'ro', required=>1);
  sub bar { 'bar' }

  $INC{'MyApp/Model/Z.pm'} = __FILE__;
  
  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  no warnings::illegalproto;

  sub test_model($ctx, $Req, $Res, $BodyData, $BodyParams, $QueryParams, Model::A, Model::Z) 
    :Local :Does(MethodSignatureDependencyInjection) UsePrototype(1)
   {
    my ($self, $Ctx, $Req, $Res, $Data, $Params, $Query, $A, $Z) = @_;

    Test::Most::is ref($Ctx), 'MyApp';
    Test::Most::is ref($Req), 'Catalyst::Request';
    Test::Most::is ref($Res), 'Catalyst::Response';
    Test::Most::is ref($A), 'MyApp::Model::A';
    Test::Most::is ref($Z), 'MyApp::Model::Z';

    $Ctx->res->body('test');
  }

  sub test_model2 :Local :Does(MethodSignatureDependencyInjection)
    ExecuteArgsTemplate($ctx, $Req, $Res, $BodyData, $BodyParams, $QueryParams, Model::A, Model::Z)
   {
    my ($self, $Ctx, $Req, $Res, $Data, $Params, $Query, $A, $Z) = @_;

    Test::Most::is ref($Ctx), 'MyApp';
    Test::Most::is ref($Req), 'Catalyst::Request';
    Test::Most::is ref($Res), 'Catalyst::Response';
    Test::Most::is ref($A), 'MyApp::Model::A';
    Test::Most::is ref($Z), 'MyApp::Model::Z';

    $Ctx->res->body('test');
  }

  sub test_arg($ctx, $res, Arg0) :Local Args(1) Does(MethodSignatureDependencyInjection) UsePrototype(1)
  {
    my ($self, $c, $res, $arg) = @_;
    $res->body($arg);
  }

  sub test_arg2($ctx, $res, Arg, $arg) :Local Args(2) Does(MethodSignatureDependencyInjection) UsePrototype(1)
  {
    my ($self, $c, $res, $arg1, $arg2) = @_;
    $res->body("$arg2.$arg1");
  }

  sub normal :Local Args(1) {
    my ($self, $c, $arg) = @_;

    Test::Most::is ref($c), 'MyApp';
    Test::Most::is ref($self), 'MyApp::Controller::Root';
    Test::Most::is $arg, 111;
  }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  package MyApp;
  use Catalyst;
  
  MyApp->config(
    'Model::A' => {aaa=>100},
    'Model::Z' => {zzz=>200},  
  );
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request('/root/test_model');

  is ref($c->model('A')), 'MyApp::Model::A';
  is $c->model('A')->foo, 'foo';
  is $c->model('A')->aaa, 100;
  is $c->model('Z')->bar, 'bar';
  is $c->model('Z')->zzz, 200;
}

{
  my ($res, $c) = ctx_request('/root/test_model2');

  is ref($c->model('A')), 'MyApp::Model::A';
  is $c->model('A')->foo, 'foo';
  is $c->model('A')->aaa, 100;
  is $c->model('Z')->bar, 'bar';
  is $c->model('Z')->zzz, 200;
}

{
  ok my $res = request('/root/normal/111');
}

{
  ok my $res = request('/root/test_arg/111');
  is $res->content, '111';
}

{
  ok my $res = request('/root/test_arg2/111/222');
  is $res->content, '222.111';
}


done_testing(28);
