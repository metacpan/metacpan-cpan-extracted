use Test::Most;

{
  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  sub bag :Local {
    pop->res->body('bag');
  }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  package MyApp;
  
  use Catalyst qw/DataHash/;

  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request( '/root/bag' );

  ok $c->model->isa('MyApp::Model::DataHash');
  ok $c->model->set(a=>1,b=>2);
  is $c->model->get('a'), 1;
  is $c->model->get('b'), 2;
  is $c->model->a, 1;
  is $c->model->b, 2;

  ok !eval {$c->model->get('f')};
  ok !eval {$c->model->f};
  ok !eval {$c->model->set(a=>2)};

  ok $c->model->delete('a');
  ok $c->model->set(a=>2);


}

done_testing;
