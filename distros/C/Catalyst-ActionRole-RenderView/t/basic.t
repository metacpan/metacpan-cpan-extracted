use Test::Most;

{  
  package MyApp::View::Hello;
  $INC{'MyApp/View/Hello.pm'} = __FILE__;

  use base 'Catalyst::View';

  sub process {
    my ($self, $c) = @_;
    $c->res->body('hello');
  }

  package MyApp::Controller::Root;
  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub test :Local Args(0) {
    my ($self, $c) = @_;
    $c->view('Hello');
  }

  sub end : Action Does(RenderView) {}

  MyApp::Controller::Root->config(namespace=>'');

  package MyApp;
  $INC{'MyApp.pm'} = __FILE__;

  use Catalyst;
  
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  ok my $res = request '/test';
  is $res->content, 'hello';
}

done_testing;
