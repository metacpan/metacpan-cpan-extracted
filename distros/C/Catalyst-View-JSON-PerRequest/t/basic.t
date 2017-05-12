use Test::Most;

{
  package Catalyst::View::JSON::PerRequest::Dummy;

  sub TO_JSON {
    die 'Died in Catalyst::View::JSON::PerRequest::Dummy::TO_JSON';
  }

  package MyApp::Model::Person;

  use Moo;
  extends 'Catalyst::Model';

  has [qw/first_name last_name age/] => (is=>'rw');

  sub TO_JSON {
    my $self = shift;
    return {
      time => scalar(localtime),
      fname => $self->first_name,
      lname => $self->last_name,
      age => $self->age };
  }

  sub ACCEPT_CONTEXT {
    my ($self, $c, @args) = @_;
    return ref($self)->new(@args);
  }

  $INC{'MyApp/Model/Person.pm'} = __FILE__;

  package MyApp::View::JSON;

  use Moo;
  extends 'Catalyst::View::JSON::PerRequest';

  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  $INC{'MyApp/View/JSON.pm'} = __FILE__;

  sub example :Local Args(0) {
    my ($self, $c) = @_;
    $c->view->ok({
        a => 1,
        b => 2,
        c => 3,
      });
  }

  sub custom :Local Args(0) {
    my ($self, $c) = @_;
    $c->view->data('Person');
    $c->view->data->last_name('nap');
    $c->view->data->first_name('john');
    $c->view->ok({age => 44});
  }

  sub object :Local Args(0) {
    my ($self, $c) = @_;
    $c->view->ok(
      $c->model('Person',
        first_name => 'M', 
        last_name => 'P',
        age => 20));
  }

  sub error_global :Local Args(0) {
    my ($self, $c) = @_;
    $c->view->ok( bless +{}, 'Catalyst::View::JSON::PerRequest::Dummy');
  }

  sub error_local :Local Args(0) {
    my ($self, $c) = @_;

    $c->view->handle_encode_error(sub {
      my ($view, $err) = @_;
      $view->detach_service_unavailable({ error => "$err"});
    });

    $c->view->ok( bless +{}, 'Catalyst::View::JSON::PerRequest::Dummy');
  }

  sub root :Chained('/') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->view->data->set(z=>1);
  }

  sub a :Chained(root) CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->view->data->set(y=>1);

  }

  sub b :Chained(a) Args(0) {
    my ($self, $c) = @_;
    $c->view->created({
        a => 1,
        b => 2,
        c => 3,
      });
  }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  package MyApp;
  
  use Catalyst;

  MyApp->config(
    default_view =>'JSON',
    'Controller::Root' => { namespace => '' },
    'View::JSON' => {
      handle_encode_error => \&Catalyst::View::JSON::PerRequest::HANDLE_ENCODE_ERROR,
    },
  );

  MyApp->setup;
}

use Catalyst::Test 'MyApp';
use JSON::MaybeXS;

{
  ok my ($res, $c) = ctx_request( '/example' );
  is $res->code, 200;
  
  my %json = %{ decode_json $res->content };

  is $json{a}, 1;
  is $json{b}, 2;
  is $json{c}, 3;
}

{
  ok my ($res, $c) = ctx_request( '/root/a/b' );
  is $res->code, 201;
  
  my %json = %{ decode_json $res->content };

  is $json{a}, 1;
  is $json{b}, 2;
  is $json{c}, 3;
  is $json{y}, 1;
  is $json{z}, 1;
}

{
  ok my ($res, $c) = ctx_request( '/custom' );
  is $res->code, 200;
  
  my %json = %{ decode_json $res->content };

  is $json{fname}, 'john';
  is $json{lname}, 'nap';
  is $json{age}, 44;
  ok $json{time};
}

{
  ok my ($res, $c) = ctx_request( '/object' );
  is $res->code, 200;
  
  my %json = %{ decode_json $res->content };

  is $json{fname}, 'M';
  is $json{lname}, 'P';
  is $json{age}, 20;
  ok $json{time};
}

{
  ok my ($res, $c) = ctx_request( '/error_global' );
  is $res->code, 500;
  
  my %json = %{ decode_json $res->content };
  ok $json{error};
}

{
  ok my ($res, $c) = ctx_request( '/error_local' );
  is $res->code, 503;
  
  my %json = %{ decode_json $res->content };
  ok $json{error};
}

done_testing;
