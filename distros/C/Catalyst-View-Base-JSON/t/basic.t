use Test::Most;

{
  package MyApp::View::Person;

  use Moo;
  extends 'Catalyst::View::Base::JSON';

  has [qw/name age api_version/] => (is=>'ro', required=>1);

  sub TO_JSON {
    my $self = shift;
    return +{
      name => $self->name,
      age => $self->age,
      api => $self->api_version,
    };
  }

  $INC{'MyApp/View/Person.pm'} = __FILE__;

  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  sub example :Local Args(0) {
    my ($self, $c) = @_;
    $c->stash(age=>32);
    $c->view('Person', name=>'John')->http_ok;
  }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  package MyApp;
  
  use Catalyst;

  MyApp->config(
    'Controller::Root' => { namespace => '' },
    'View::Person' => {
      returns_status => [200, 404],
      api_version => '1.1',
    },
  );

  MyApp->setup;
}

use Catalyst::Test 'MyApp';
use JSON::MaybeXS;

{
  ok my ($res, $c) = ctx_request( '/example' );
  is $res->code, 200;
  
  ok my %json = eval { %{ decode_json $res->content } };
  is $json{name}, 'John';
  is $json{age}, '32';
  is $json{api}, '1.1';
}

done_testing;
