package TestApp::Controller::Auth;

use strict;
use warnings;
use base qw( Catalyst::Controller );

sub user_login : Local {
  my ($self, $c) = @_;

  $c->authenticate({
    username => $c->req->params->{username},
    password => $c->req->params->{password},
  });

  $c->forward('do_the_rest');
}

sub notdisabled_login : Local {
  my ($self, $c) = @_;

  $c->authenticate({
    username => $c->req->params->{username},
    password => $c->req->params->{password},
    status   => [ 'active', 'registered' ],
  });

  $c->forward('do_the_rest');
}

sub limit_args_login : Local {
  my ($self, $c) = @_;

  my $username = $c->req->params->{username} || '';
  my $email    = $c->req->params->{email}    || '';

  $c->authenticate({
    password => $c->req->params->{password},
    jifty_dbi => {
      limit_args => [{
        column    => 'username',
        value     => $username,
        subclause => 'or_condition',
      },
      {
        column    => 'email',
        value     => $email,
        subclause => 'or_condition',
      }],
    }
  });

  $c->forward('do_the_rest');
}

sub collection_login : Local {
  my ($self, $c) = @_;

  my $username = $c->req->params->{username} || '';
  my $email    = $c->req->params->{email}    || '';

  my $collection = $c->model('TestDB::UserCollection');
     $collection->limit(
       column    => 'username',
       value     => $username,
       subclause => 'or_condition',
     );
     $collection->limit(
       column    => 'email',
       value     => $email,
       subclause => 'or_condition',
     );

  $c->authenticate({
    password  => $c->req->params->{password},
    jifty_dbi => { collection => $collection },
  });

  $c->forward('do_the_rest');
}

sub do_the_rest : Private {  # maybe 'end' is enough?
  my ($self, $c) = @_;

  if ( $c->user_exists ) {
    if ( $c->req->params->{detach} ) {
      $c->detach( $c->req->params->{detach} );
    }
    $c->res->body( $c->user->get('username') . ' logged in' );
  }
  else {
    $c->res->status(401);
    $c->res->body('not logged in');
  }
}

sub user_logout : Local {
  my ($self, $c) = @_;

  $c->logout;

  $c->detach('/error') if $c->user;

  $c->res->body('logged out');
}

sub get_session_user : Local {
  my ($self, $c) = @_;

  $c->res->body( $c->user_exists ? $c->user->get('username') : '' );
}

sub is_admin : Local {
  my ($self, $c) = @_;

  eval {
    if ( $c->assert_user_roles(qw( admin )) ) {
      $c->res->body('ok');
    }
  };
  $c->detach('/error') if $@;
}

sub is_admin_user : Local {
  my ($self, $c) = @_;

  eval {
    if ( $c->assert_user_roles(qw( admin user )) ) {
      $c->res->body('ok');
    }
  };
  $c->detach('/error') if $@;
}

1;
