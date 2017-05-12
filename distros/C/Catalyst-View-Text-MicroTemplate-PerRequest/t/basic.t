use Test::Most;

{
  package MyApp::Model::Person;

  use Moo;
  extends 'Catalyst::Model';

  has [qw/first_name last_name age/] => (is=>'rw');

  sub TO_HASH {
    my $self = shift;
    return (
      time => scalar(localtime),
      fname => $self->first_name,
      lname => $self->last_name,
      age => $self->age );
  }

  sub ACCEPT_CONTEXT {
    my ($self, $c, @args) = @_;
    return ref($self)->new(@args);
  }

  $INC{'MyApp/Model/Person.pm'} = __FILE__;

  package MyApp::View::HTML;

  use Moo;
  extends 'Catalyst::View::Text::MicroTemplate::PerRequest';

  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  $INC{'MyApp/View/Text/MicroTemplate.pm'} = __FILE__;

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
    $c->view->ok( bless +{}, 'Catalyst::View::Text::MicroTemplate::PerRequest::Dummy');
  }

  sub error_local :Local Args(0) {
    my ($self, $c) = @_;

    $c->view->handle_process_error(sub {
      my ($view, $err) = @_;
      $view->template('503');
      $view->detach_service_unavailable({ error => "$err"});
    });

    $c->view->ok( bless +{}, 'Catalyst::View::JSON::PerRequest::Dummy');
  }

  sub root :Chained(/) CaptureArgs(0) {
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

  sub default_template :Chained(root) Args(0) {
    my ($self, $c) = @_;
    $c->view->template_factory(sub {
      my ($view, $ctx) = @_;
      return $ctx->response->status > 299 ?
        "${\$ctx->action}_${\$ctx->res->status}" :
          "${\$ctx->action}";
    });

    $c->view->bad_request({message=>"bad bad bad"});
  }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  package MyApp;
  
  use Catalyst;
  use Path::Class::Dir;

  MyApp->config(
    'root' => Path::Class::Dir->new('.','t'),
    default_view =>'HTML',
    'Controller::Root' => { namespace => '' },
    'View::HTML' => {
      content_type => 'text/html',
      handle_process_error => \&Catalyst::View::Text::MicroTemplate::PerRequest::HANDLE_PROCESS_ERROR,
    },
  );

  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  ok my ($res, $c) = ctx_request( '/example' );
  is $res->code, 200;
  like $res->content, qr/\$a:1/;
}

{
  ok my ($res, $c) = ctx_request( '/root/a/b' );
  is $res->code, 201;
  like $res->content, qr/\$a:1,\$b:2,\$c:3,\$y:1,\$z:1/;  
}

{
  ok my ($res, $c) = ctx_request( '/custom' );
  is $res->code, 200;
  like $res->content, qr/\$fname:john,\$age:44/;
}

{
  ok my ($res, $c) = ctx_request( '/error_global' );
  is $res->code, 500;
  like $res->content, qr/could not find template file: error_global\.mt /;
}

{
  ok my ($res, $c) = ctx_request( '/error_local' );
  is $res->code, 503;
  like $res->content, qr/could not find template file: error_local\.mt /;
}

{
  ok my ($res, $c) = ctx_request( '/root/default_template' );
  is $res->code, 400;
  like $res->content, qr/bad bad bad/;
}

done_testing;
