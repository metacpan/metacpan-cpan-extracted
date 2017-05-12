use Test::Most;
use HTTP::Request::Common;
use Scalar::Util qw/refaddr/;

BEGIN {
  package MyApp::Role::Test;
  $INC{'MyApp/Role/Test.pm'} = __FILE__;

  use Moose::Role;

  sub TO_JSON { 'json' }

  package MyApp::Role::TestOne;
  $INC{'MyApp/Role/TestOne.pm'} = __FILE__;

  use Moose::Role;

  sub TO_JSON_2 { 'json2' }

  package MyApp::Form::Email;
  $INC{'MyApp/Form/Email.pm'} = __FILE__;

  use HTML::FormHandler::Moose;

  extends 'HTML::FormHandler';

  has aaa => (is=>'ro', required=>1);
  has bbb => (is=>'ro', required=>1);

  has_field 'email' => (
    type=>'Email',
    size => 96,
    required => 1);

  package MyApp::Form::User;
  $INC{'MyApp/Form/User.pm'} = __FILE__;

  use HTML::FormHandler::Moose;

  extends 'HTML::FormHandler';

  has_field 'name' => (
    type=>'Text',
    size => 96,
    required => 1);
}

{
  package MyApp::Model::Form;

  use Moose;
  extends 'Catalyst::Model::HTMLFormhandler';

  $INC{'MyApp/Model/Form.pm'} = __FILE__;

  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  sub form :Local {
    my ($self, $c) = @_;
    $c->res->body('form')
  }

  sub test_process :POST Local {
    my ($self, $c) = @_;
    my $form = $c->model('Form::Email',bbb=>2000);
    Test::Most::ok $form->is_valid;
    $c->res->body($form->render)
  }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  package MyApp::Controller::Example;
  use base 'Catalyst::Controller';

  sub get_form :GET Path('') Args(0) {
    my ($self, $c) = @_;
  }

  sub post_form :POST Path('') Args(0) FormModelTarget(Form::Email) {
    my ($self, $c) = @_;
  }

  package MyApp;
  use Catalyst;

  MyApp->config(
    'Controller::Root' => {namespace => ''},
    'Model::Form' => { roles => ['MyApp::Role::Test', 'MyApp::Role::TestOne'] },
    'Model::Form::Email' => { aaa => 1000 }
  );
  
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request( '/form' );
  ok my $link = $c->controller('Root')->action_for('form');
  ok my $email = $c->model('Form::Email', action_from=>$link,bbb=>2000);
  is $email->aaa, 1000;
  is $email->bbb, 2000;
  is $email->TO_JSON, 'json';
  is $email->TO_JSON_2, 'json2';
  ok $email->ctx;
  ok $email->process(params=>{email=>'jjn1056@yahoo.com'});
  ok !$email->process(params=>{email=>'jjn1056oo.com'});
  ok $c->model('Form::Email', {email=>'jjn1056@yahoo.com'})->is_valid;
  ok !$c->model('Form::Email', {email=>'jjn1056oo.com'})->is_valid;
  is $email->action, 'http://localhost/form';
}

{
  my ($res, $c) = ctx_request POST '/example' , [email=>'jjn1056@yahoo.com'];
  ok my $email = $c->model('Form::Email', (bless {}, 'foo'), bbb=>2000);
  ok $email->item->isa('foo');
  ok $email->is_valid;
  is $email->values->{email}, 'jjn1056@yahoo.com';
  is $email->action, 'http://localhost/example';
  is refaddr($email), refaddr(my $e2 = $c->model('Form::Email'));

  ok $email->is_valid;
  ok $e2->is_valid;

  ok $c->model('Form::Email')->is_valid;
  ok $c->model('Form::Email::IsValid');
  ok !$c->model('Form::Email::IsValid', {email=>'asdasd'});
}

done_testing;
