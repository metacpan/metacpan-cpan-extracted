BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90090; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
}

{
  package MyApp::Model::Depending;
  $INC{'MyApp/Model/Depending.pm'} = __FILE__;

  use Moose;
  extends 'Catalyst::Model';

  has aaa => (is=>'ro', required=>1);
  has bbb => (is=>'ro', required=>1);
  has code => (is=>'ro', required=>1);

  package MyApp::Model::Normal;
  $INC{'MyApp/Model/Normal.pm'} = __FILE__;

  use Moose;
  extends 'Catalyst::Model';

  has ccc => (is=>'ro', required=>1);

  package MyApp::Controller::Example;
  $INC{'MyApp/Controller/Example.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub test :Local Args(0) {
    my ($self, $c) = @_;
    $c->res->body('test');
  }

  package MyApp;

  use Catalyst qw/MapComponentDependencies/;
  
  MyApp->config(
    'Model::Normal' => { ccc => 300 },
    'Model::Depending' => { bbb => 200 },
    'Plugin::MapComponentDependencies' => {
      map_dependencies => {
        'Model::Depending' => {
          aaa => 'Model::Normal',
          code => sub {
            my ($app, $component_name) = @_;
            return 1;
          },
        },
      },
    },
  );

  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request( '/example/test' );

  is $c->model('Normal')->ccc, 300;
  is $c->model('Depending')->bbb, 200;
  is $c->model('Depending')->aaa->ccc, 300;
  is $c->model('Depending')->code, 1;
}

done_testing;
