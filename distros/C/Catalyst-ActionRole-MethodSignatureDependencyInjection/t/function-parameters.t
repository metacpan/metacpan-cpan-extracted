BEGIN {
  use Test::Most;
  eval "use Function::Parameters 1.0605; 1" || do {
    plan skip_all => "Need Function::Parameters to run this test => $@";
  };
}

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

  use Function::Parameters({
    method => {defaults => 'method'},
    action => {
      attributes => ':method :Does(MethodSignatureDependencyInjection) UsePrototype(1)',
      shift => '$self',
      check_argument_types => 0,
      strict => 0,
      default_arguments => 1,
    }});

  action test_model($c, $Req, $Res, $BodyData, $BodyParams, $QueryParams, Model::A $A, Model::Z $Z) 
    :Local 
  {
    Test::Most::is ref($self), 'MyApp::Controller::Root';
    Test::Most::is ref($c), 'MyApp';
    Test::Most::is ref($Req), 'Catalyst::Request';
    Test::Most::is ref($Res), 'Catalyst::Response';
    Test::Most::is ref($A), 'MyApp::Model::A';
    Test::Most::is ref($Z), 'MyApp::Model::Z';
  }

  method test($a) {
    return $a;
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
  is $c->controller->test('foo'), 'foo';
}

done_testing(12);
