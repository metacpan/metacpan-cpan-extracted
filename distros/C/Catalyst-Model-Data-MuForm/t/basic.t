use Test::Most;
use HTTP::Request::Common;
use Scalar::Util qw/refaddr/;

BEGIN {

  package MyApp::Form::Email;
  $INC{'MyApp/Form/Email.pm'} = __FILE__;

  use Moo;
  use Data::MuForm::Meta;
  extends 'Data::MuForm';

  has aaa => (is=>'ro', required=>1);
  has bbb => (is=>'ro', required=>1);

  has_field 'email' => (
    type=>'Email',
    size => 96,
    required => 1);

  package MyApp::Form::User;
  $INC{'MyApp/Form/User.pm'} = __FILE__;

  use Moo;
  use Data::MuForm::Meta;
  extends 'Data::MuForm';

  has_field 'name' => (
    type=>'Text',
    size => 96,
    required => 1);
}

{
  package MyApp::Model::Form;

  use Moo;
  extends 'Catalyst::Model::Data::MuForm';

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
    Test::Most::ok $form->validated;
    $c->res->body($form->render)
  }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  package MyApp::Controller::Example;
  use base 'Catalyst::Controller';

  sub get_form :GET Path('') Args(0) {
    my ($self, $c) = @_;
  }

  sub post_form :POST Path('') Args(0) {
    my ($self, $c) = @_;
  }

  package MyApp;
  use Catalyst;

  MyApp->config(
    'Controller::Root' => {namespace => ''},
    'Model::Form' => { roles => ['MyApp::Role::Test', 'MyApp::Role::TestOne'] },
    'Model::Form::Email' => { aaa => 1000, bbb => 2000 }
  );
  
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request( '/form' );
  ok my $link = $c->controller('Root')->action_for('form');
  ok my $email = $c->model('Form::Email');
  is $email->aaa, 1000;
  is $email->bbb, 2000;
  ok $email->ctx;
  ok $email->process(params=>{email=>'jjn1056@yahoo.com'});
  ok !$email->process(params=>{email=>'jjn1056oo.com'});
  ok $c->model('Form::Email', params=>{email=>'jjn1056@yahoo.com'})->validated;
  ok !$c->model('Form::Email', params=>{email=>'jjn1056oo.com'})->validated;
}

{
  my ($res, $c) = ctx_request POST '/example' , [email=>'jjn1056@yahoo.com'];
  ok my $email = $c->model('Form::Email', (bless {}, 'foo'));
  ok $email->model->isa('foo');
  ok $email->validated;
  is $email->values->{email}, 'jjn1056@yahoo.com';
  ok $email->validated;
  ok $c->model('Form::Email')->validated;
}

done_testing;
