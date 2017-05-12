BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90093; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
  eval "use Types::Standard ; 1" || do {
    plan skip_all => "You need Types::Standard for this test => $@";
  };

}

{
  package MyApp::Controller::Root;
  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  use base 'Catalyst::Controller';
  use Types::Standard 'Int';

  MyApp::Controller::Root->config(
    namespace    => '',
    action_roles => ['QueryParameter'],
  );

  sub fail :Path('') Args {
    my ($self, $c) = @_;
    $c->res->body('fail');
  }

  sub page : Path('foo') QueryParam('page:>1') QueryParam('order') Args(0) {
    my ($self, $ctx) = @_;
    $ctx->response->body('page');
  }

  sub root :Chained(/) PathPart('') CaptureArgs(0) QueryParam(root:eqroot) { }
    sub order :Chained(root) Args(0) QueryParam(order:=~^(up|down)$) {
      my ($self, $c) = @_;
      $c->res->body('order');
    }
    sub int :Chained(root) Args(0) QueryParam(order:Int) {
      my ($self, $c) = @_;
      $c->res->body('order');
    }
  
  package MyApp::Controller::Example;
  $INC{'MyApp/Controller/Example.pm'} = __FILE__;

  use base 'Catalyst::Controller';


  package MyApp;
  use Catalyst;
  
  MyApp->setup;
}

use HTTP::Request::Common;
use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request( '/foo?page=2&order=2' );
  is $res->content, 'page';
}

{
  my ($res, $c) = ctx_request( '/order?page=2&order=2' );
  is $res->content, 'fail';
}

{
  my ($res, $c) = ctx_request( '/order?root=root&order=2' );
  is $res->content, 'fail';
}

{
  my ($res, $c) = ctx_request( '/order?root=root&order=upt' );
  is $res->content, 'fail';
}

{
  my ($res, $c) = ctx_request( '/order?root=root&order=up' );
  is $res->content, 'order';
}

{
  my ($res, $c) = ctx_request( '/int?root=root&int=up' );
  is $res->content, 'fail';
}

done_testing;

