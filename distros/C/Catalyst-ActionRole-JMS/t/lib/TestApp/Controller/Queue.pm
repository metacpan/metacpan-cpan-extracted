package TestApp::Controller::Queue;
use Moose;
use namespace::autoclean;
use Data::Printer;

BEGIN { extends 'Catalyst::Controller::JMS' }

__PACKAGE__->config(
    namespace => 'queue/myq',
);

sub foo :MessageTarget {
    my ($self,$c) = @_;

    $c->log->debug('Message received "foo"'.p($c->req->data))
        if $c->debug;

    $c->stash->{message} = $c->req->data;

    return;
}

sub bar :MessageTarget {
    my ($self,$c) = @_;

    $c->log->debug('Message received "bar"'.p($c->req->data))
        if $c->debug;

    $c->stash->{message} = {my=>'return'};

    return;
}

sub default :Default {
    my ($self,$c) = @_;

    $c->log->debug('Message dispatched to default'.p($c->req->data))
        if $c->debug;

    return;
}

1;
