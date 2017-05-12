package TestApp::Controller::DB;

use strict;
use warnings;
use base qw( Catalyst::Controller );

sub setup : Local {
  my ($self, $c) = @_;

  my $database = $c->model('TestDB')->database;

  if ( $database && -f $database && -s $database ) {
    $c->res->body('ok');
    return 1;
  }

  eval {
    $c->model('TestDB')->setup_database;
    die unless !$database or -f $database;

    $c->model('TestDB::User')->create(
      username  => 'joeuser',
      password  => 'hackme',
      email     => 'joeuser@nowhere.com',
      status    => 'active',
      role_text => 'admin',
    );
    $c->model('TestDB::User')->create(
      username  => 'spammer',
      password  => 'broken',
      email     => 'bob@spamhous.com',
      status    => 'disabled',
    );
    my $jayk = $c->model('TestDB::User')->create(
      username  => 'jayk',
      password  => 'letmein',
      email     => 'j@cpants.org',
      status    => 'active',
    );
    my $nuffin = $c->model('TestDB::User')->create(
      username  => 'nuffin',
      password  => 'much',
      email     => 'nada@mucho.net',
      status    => 'registered',
      role_text => 'user admin',
    );

    my $admin = $c->model('TestDB::Role')->create(
      role => 'admin',
    );
    my $user = $c->model('TestDB::Role')->create(
      role => 'user',
    );

    $c->model('TestDB::UserRole')->create(
      user => $jayk,
      role => $admin,
    );
    $c->model('TestDB::UserRole')->create(
      user => $jayk,
      role => $user,
    );
    $c->model('TestDB::UserRole')->create(
      user => $nuffin,
      role => $user,
    );
  };
  $c->detach('/error') if $@;

  $c->res->body('ok');
}

sub teardown : Local {
  my ($self, $c) = @_;

  $c->model('TestDB')->disconnect;

  my $dbfile = $c->model('TestDB')->database;
  if ( $dbfile && -f $dbfile ) {
    unlink $dbfile or $c->detach('/error');
  }

  $c->res->body('ok');
}

1;
