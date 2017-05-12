package PerUserTestApp;
use Catalyst qw/
  Session
  Session::Store::Dummy
  Session::State::Cookie

  Session::PerUser

  Authentication
  Authentication::Store::Minimal
  /;
  
use User::WithSession;

__PACKAGE__->config->{authentication}{users} = {
    foo   => { id                       => "foo" },
    bar   => { id                       => "bar" },
    gorch => User::WithSession->new( id => "gorch" ),
};

__PACKAGE__->setup;

1;
