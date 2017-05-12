use Test::Most;

{
  package MyApp::Model::ReturnsNull;
  $INC{'MyApp/Model/ReturnsNull.pm'} = __FILE__;

  use Moose;
  extends 'Catalyst::Model';

  sub ACCEPT_CONTEXT { return undef  }


  package MyApp::Model::ReturnsTrue;
  $INC{'MyApp/Model/ReturnsTrue.pm'} = __FILE__;

  use Moose;
  extends 'Catalyst::Model';

  sub ACCEPT_CONTEXT { return shift  }
  
  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  no warnings::illegalproto;

  sub null_ok( Model::ReturnsNull, Model::ReturnsTrue) :Local
   :Does(MethodSignatureDependencyInjection) UsePrototype(1)
  {
    my ($self, $null, $true) = @_;
    Test::Most::ok !$null, 'not null';
    Test::Most::ok $true, 'true is true';
  }

  sub no_null_1( $c, Model::ReturnsNull, Model::ReturnsTrue) :Path('no_null')
   :Does(MethodSignatureDependencyInjection) UsePrototype(1)
  {
    my ($self, $c) = @_;
    return $c->res->body('no_null_1');
  }

  sub no_null_2( $c, Model::ReturnsNull required, Model::ReturnsTrue required) :Path('no_null')
   :Does(MethodSignatureDependencyInjection) UsePrototype(1)
  {
    my ($self, $c) = @_;
    return $c->res->body('no_null_2');
  }

  sub chainroot :Chained(/) PathPrefix CaptureArgs(0) {  }

    sub no_null_chain_1( $c, Model::ReturnsNull, Model::ReturnsTrue) :Chained(chainroot) PathPart('no_null_chain')
     :Does(MethodSignatureDependencyInjection) UsePrototype(1)
    {
      my ($self, $c) = @_;
      return $c->res->body('no_null_chain_1');
    }

    sub no_null_chain_2( $c, Model::ReturnsNull required, Model::ReturnsTrue required) :Chained(chainroot) PathPart('no_null_chain')
     :Does(MethodSignatureDependencyInjection) UsePrototype(1)
    {
      my ($self, $c) = @_;
      return $c->res->body('no_null_chain_2');
    }



  package MyApp;
  use Catalyst;
  
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request('/root/null_ok');
}

{
  my ($res, $c) = ctx_request('/root/no_null');
  is $res->content, 'no_null_1', 'expected value no_null1';
}


{
  my ($res, $c) = ctx_request('/root/no_null_chain');
  is $res->content, 'no_null_chain_1', 'expected value no_null_chain_1';
}

done_testing;
