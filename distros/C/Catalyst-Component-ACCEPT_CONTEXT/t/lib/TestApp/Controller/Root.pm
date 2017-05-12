# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package TestApp::Controller::Root;
use strict;
use warnings;
use base qw/Catalyst::Component::ACCEPT_CONTEXT Catalyst::Controller/;
use Devel::Cycle;

__PACKAGE__->config(namespace => '');

sub model : Global {
    my ($self, $c) = @_;
    $c->stash->{message} = "model";
    $c->res->body($c->model('Test')->message);
}

sub view : Global {
    my ($self, $c) = @_;
    $c->stash->{message} = "view";
    $c->res->body($c->view('Test')->message);
}

sub controller : Global {
    my ($self, $c) = @_;
    $c->res->body("controller");
}

sub foo : Global {
    my ($self, $c) = @_;
    $c->res->body($c->model('Test')->foo);
}

sub stash : Global {
    my ($self, $c) = @_;
    $c->model('StashMe')->test;
    $c->res->body($c->stash->{stashme}->foo);
}

sub cycle : Global {
    my ($self, $c) = @_;
    $c->model('StashMe')->test;
    my $cycle_ok = 1;
    my $got_cycle = sub { $cycle_ok = 0 };
    find_cycle($c, $got_cycle);
    $c->res->body($cycle_ok);
} 

sub weak_cycle :Global {
    my ($self, $c) = @_;
    $c->model('StashMe')->test;
    my $cycle_ok = 0;
    my $got_cycle = sub { $cycle_ok = 1 };
    find_weakened_cycle($c, $got_cycle);
    $c->res->body($cycle_ok);
}

1;

