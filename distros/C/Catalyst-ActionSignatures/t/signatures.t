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

  package MyApp::Controller::Example;

  use Moose;
  use MooseX::MethodAttributes;
  use Catalyst::ActionSignatures;

  extends 'Catalyst::Controller';

  has aaa => (is=>'ro', required=>1, default=>100);
  
  sub test($Req, $Res, Model::A $A, Model::Z $Z) :Local {
    Test::Most::is ref($c), 'MyApp';
    Test::Most::is ref($Req), 'Catalyst::Request';
    Test::Most::is ref($Res), 'Catalyst::Response';
    Test::Most::is ref($A), 'MyApp::Model::A';
    Test::Most::is ref($Z), 'MyApp::Model::Z';

    $c->res->body($self->regular(200));
  }

  sub test_arg($res, Arg0 $id, Arg1 $pid, Model::A $a) :Local Args(2) {
    $res->body("$id+$pid");
  }

  sub regular($arg) {
    return "${\$self->aaa} $arg";
  }

  sub old_school {
    return 1;
  }

  sub argsargs($res, Args @ids) :Local {
    $res->body(join ',', @ids);
  }

  sub chain(Model::A $a, Capture $id isa '"Int"', $res) :Chained(/) {
    Test::Most::is $id, 100;
    Test::Most::ok $res->isa('Catalyst::Response');
  }

    sub endchain($res, Arg0 $name) :Chained(chain)  {
      $res->body($name);
    }
 
    sub endchain2($res, Arg $first, Arg $last) :Chained(chain) PathPart(endchain)  {
      $res->body("$first $last");
    }

    sub typed0($res, Arg $id) :Chained(chain) PathPart(typed) {
      $res->body('any');
    }

    sub typed1($res, Arg $pid isa '"Int"') :Chained(chain) PathPart(typed) {
      $res->body('int');
    }

  sub another_chain() :Chained(/) { }

    sub another_end($res) :Chained(another_chain/)  { $res->body('another_end') }


  package MyApp::Controller::Quoted;

  use Moose;
  use MooseX::MethodAttributes;
  use Catalyst::ActionSignatures;

  extends 'Catalyst::Controller';

  has aaa => (is=>'ro', required=>1, default=>100);
  
  sub test($Req, $Res, Model::A $A, Model::Z $Z) :Local {
    Test::Most::is ref($c), 'MyApp';
    Test::Most::is ref($Req), 'Catalyst::Request';
    Test::Most::is ref($Res), 'Catalyst::Response';
    Test::Most::is ref($A), 'MyApp::Model::A';
    Test::Most::is ref($Z), 'MyApp::Model::Z';

    $c->res->body($self->regular(200));
  }

  sub test_arg($res, Arg0 $id, Arg1 $pid, Model::A $a) :Local Args('2') {
    $res->body("$id+$pid");
  }

  sub regular($arg) {
    return "${\$self->aaa} $arg";
  }

  sub old_school {
    return 1;
  }

  sub argsargs($res, Args @ids) :Local {
    $res->body(join ',', @ids);
  }

  sub chain(Model::A $a, Capture $id isa '"Int"', $res) :Chained('/') PathPrefix {
    Test::Most::is $id, 100;
    Test::Most::ok $res->isa('Catalyst::Response');
  }

    sub endchain($res, Arg0 $name) :Chained('chain')  {
      $res->body($name);
    }
 
    sub endchain2($res, Arg $first, Arg $last) :Chained('chain') PathPart('endchain')  {
      $res->body("$first $last");
    }

    sub typed0($res, Arg $id) :Chained('chain') PathPart('typed') {
      $res->body('any');
    }

    sub typed1($res, Arg $pid isa '"Int"') :Chained('chain') PathPart('typed') {
      $res->body('int');
    }

  sub another_chain() :Chained('/') PathPrefix { }

    sub another_end($res) :Chained('another_chain/')  { $res->body('another_end') }

  package MyApp;
  use Catalyst;
  
  MyApp->config(
    'Model::A' => { aaa => 100 },
    'Model::Z' => { zzz => 200 },
  );
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request('/example/test');

  is ref($c->model('A')), 'MyApp::Model::A', 'got a';
  is $c->model('A')->foo, 'foo';
  is $c->model('A')->aaa, 100;
  is $c->model('Z')->bar, 'bar';
  is $c->model('Z')->zzz, 200;
  is $res->content, '100 200';
}

{
  ok my $res = request('/example/test_arg/111/222');
  is $res->content, '111+222';
}

{
  ok my $res = request('/chain/100/endchain/john');
  is $res->content, 'john';
}

{
  ok my $res = request('/chain/100/endchain/john/nap');
  is $res->content, 'john nap';
}

{
  ok my $res = request('/example/argsargs/');
  is $res->content, '';
}

{
  ok my $res = request('/example/argsargs/11');
  is $res->content, '11';
}

{
  ok my $res = request('/example/argsargs/11/22/33');
  is $res->content, '11,22,33';
}

{
  ok my $res = request('/chain/100/typed/string');
  is $res->content, 'any';
}

{
  ok my $res = request('/chain/100/typed/200');
  is $res->content, 'int';
}

{
  ok my $res = request('/another_chain/another_end');
  is $res->content, 'another_end';
}

#---

{
  my ($res, $c) = ctx_request('/quoted/test');

  is ref($c->model('A')), 'MyApp::Model::A', 'got a';
  is $c->model('A')->foo, 'foo';
  is $c->model('A')->aaa, 100;
  is $c->model('Z')->bar, 'bar';
  is $c->model('Z')->zzz, 200;
  is $res->content, '100 200';
}

{
  ok my $res = request('/quoted/test_arg/111/222');
  is $res->content, '111+222';
}

{
  ok my $res = request('/quoted/100/endchain/john');
  is $res->content, 'john';
}

{
  ok my $res = request('/quoted/100/endchain/john/nap');
  is $res->content, 'john nap';
}

{
  ok my $res = request('/quoted/argsargs/');
  is $res->content, '';
}

{
  ok my $res = request('/quoted/argsargs/11');
  is $res->content, '11';
}

{
  ok my $res = request('/quoted/argsargs/11/22/33');
  is $res->content, '11,22,33';
}

{
  ok my $res = request('/quoted/100/typed/string');
  is $res->content, 'any';
}

{
  ok my $res = request('/quoted/100/typed/200');
  is $res->content, 'int';
}

{
  ok my $res = request('/quoted/another_end');
  is $res->content, 'another_end';
}

done_testing;
