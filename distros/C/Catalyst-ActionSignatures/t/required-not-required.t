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
 
  package MyApp::Model::ReturnsArg;
  $INC{'MyApp/Model/ReturnsArg.pm'} = __FILE__;

  use Moose;
  extends 'Catalyst::Model';

  sub ACCEPT_CONTEXT {
    my ($self, $c, $arg) = @_;
    return "$arg.$arg";
  }

  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  use Catalyst::ActionSignatures;  

  sub null_ok( Model::ReturnsNull $null, Model::ReturnsTrue $true) :Local {
    Test::Most::ok !$null;
    Test::Most::ok $true;
  }

  sub no_null_1(Model::ReturnsNull $null, Model::ReturnsTrue $true) :Path('no_null') {
    return $c->res->body('no_null_1');
  }

  sub no_null_2(Model::ReturnsNull $null required, Model::ReturnsTrue $true required) :Path('no_null') {
    return $c->res->body('no_null_2');
  }

  sub chainroot :Chained(/) PathPrefix CaptureArgs(0) {  }

    sub from_arg($res, Model::ReturnsArg<Arg $id isa '"Int"'> $model) :Chained(chainroot/) {
      $res->body("model $model");
    }

    sub no_null_chain_1(Model::ReturnsNull $null, Model::ReturnsTrue $true) :Chained(chainroot/) PathPart('no_null_chain') {
      return $c->res->body('no_null_chain_1');
    }

    sub no_null_chain_2(Model::ReturnsNull $null required, Model::ReturnsTrue $true required) :Chained(chainroot/) PathPart('no_null_chain') {
      return $c->res->body('no_null_chain_2');
    }

  sub with_args1(Model::ReturnsTrue $true required, Arg $id) :Path(with_args) {
    $c->res->body('with_args1');
  }

  sub with_args2(Model::ReturnsTrue $true required, Arg $id isa '"Int"') :Path(with_args) {
    $c->res->body('with_args2');
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
  is $res->content, 'no_null_1';
}

{
  my ($res, $c) = ctx_request('/root/no_null_chain');
  is $res->content, 'no_null_chain_1';
}

{
  my ($res, $c) = ctx_request('/root/with_args/100');
  is $res->content, 'with_args2';
}

{
  my ($res, $c) = ctx_request('/root/with_args/john');
  is $res->content, 'with_args1';
}

{
  my ($res, $c) = ctx_request('/root/from_arg/100');
  is $res->content, 'model 100.100';
}

done_testing;
