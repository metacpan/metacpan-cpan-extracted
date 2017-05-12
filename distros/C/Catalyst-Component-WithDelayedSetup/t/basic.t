use Test::Most;

{
  package MyApp::Model::A;

  use Moose;
  extends 'Catalyst::Model';
  with 'Catalyst::Component::WithDelayedSetup';

  has aaa => (is=>'ro', required=>1);
  has model_z => (is=>'ro', isa=>'Object', required=>1);
  
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

  sub test_model :Local {
    my ($self, $c) = @_;
    $c->res->body('test');
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

my ($res, $c) = ctx_request('/test_model');

ok $res;

is ref($c->model('A')), 'MyApp::Model::A';
is $c->model('A')->foo, 'foo';
is $c->model('A')->aaa, 100;
is $c->model('A')->model_z->bar, 'bar';
is $c->model('A')->model_z->zzz, 200;
is $c->model('Z')->bar, 'bar';
is $c->model('Z')->zzz, 200;

done_testing;
