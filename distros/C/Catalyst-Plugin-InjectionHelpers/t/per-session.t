use Scalar::Util qw/refaddr/;

BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90090; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
}

BEGIN {
  package MyApp::PerSession;
  $INC{'MyApp/PerSession.pm'} = __FILE__;

  use Moose;

  has cnt => (
    is=>'rw',
    required=>1,
    default=>0);

  has name => (
    is=>'ro',
    required=>1);

  sub request_name {
    my $self = shift;
    $self->cnt( $self->cnt +1 );
    return $self->name . $self->cnt;
  }

  sub freeze {
    my $self = shift;
    return +{ name => $self->name, cnt => $self->cnt };
  }

  sub thaw {
    my $class = shift;
    my $info = shift;
    return $class->new($info);
  }
}

{
  package MyApp::Controller::Example;
  $INC{'MyApp/Controller/Example.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub per_session :Local Args(0) {
    my ($self, $c) = @_;
    $c->res->body($c->model('PerSession')->request_name);
  }

  sub discard :Local Args(0) {
    my ($self, $c) = @_;
    $c->model('PerSession')->discard;
    $c->go('per_session');
  }

  package MyApp;
  use Catalyst qw/
    InjectionHelpers
    Session
    Session::Store::Dummy
    Session::State::Cookie/;

  MyApp->inject_components(
    'Model::PerSession' => { from_class=>'MyApp::PerSession', adaptor=>'PerSession' },
  );

  MyApp->config(
    'Model::PerSession' => {name=>'john'},
  );

  MyApp->setup;
}

use Catalyst::Test 'MyApp';
use HTTP::Request::Common;

my $cookie;

{
  ok my $res = request(GET('/example/per_session'));
  ok $cookie = $res->headers->{"set-cookie"};
  is $res->content, 'john1';
}

{
  my $res = request(GET('/example/per_session', Cookie => $cookie));
  is $res->content, 'john2';
}

{
  my $res = request(GET('/example/per_session', Cookie => $cookie));
  is $res->content, 'john3';
}

{
  my $res = request(GET('/example/per_session', Cookie => $cookie));
  is $res->content, 'john4';
}

{
  my $res = request(GET('/example/discard', Cookie => $cookie));
  is $res->content, 'john1';
}

{
  my $res = request(GET('/example/per_session', Cookie => $cookie));
  is $res->content, 'john2';
}

{
  my $res = request(GET('/example/per_session', Cookie => $cookie));
  is $res->content, 'john3';
}

done_testing;
