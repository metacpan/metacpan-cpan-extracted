package TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => q{});

use base 'Catalyst::Controller';

# your actions replace this one
sub main :Path { $_[1]->res->body('<h1>It works</h1>') }

sub session_test :Local {
    my ($self, $c) = @_;
    $c->session->{value} ||= 0;
    $c->res->body( join ',', $c->sessionid, $c->session->{value}++ );
}

sub delete :Local {
    my ($self, $c) = @_;
    $c->delete_expired_sessions;
    $c->res->body( 'ok' );
}

sub flash_set :Local {
    my ($self, $c) = @_;
    $c->flash->{foo} = 'OH HAI';
    $c->res->body( 'ok' );
};

sub flash_get :Local {
    my ($self, $c) = @_;
    $c->res->body( $c->flash->{foo} || 'NOTHING' );
}

sub cleanup :Local {
    my ($self, $c) = @_;
    my $dir = Catalyst::Utils::class2tempdir(ref $c);
    require File::Remove;
    File::Remove::remove( \1, $dir );
    $c->res->body( 'ok' );
  }
1;
