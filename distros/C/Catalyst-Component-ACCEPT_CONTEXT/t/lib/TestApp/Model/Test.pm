# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package TestApp::Model::Test;
use strict;
use warnings;
use base qw(Catalyst::Component::ACCEPT_CONTEXT Catalyst::Model);

my $foo = 'bar';
sub new {
    my $self = shift;
    $self = $self->next::method(@_);
    $foo = $self->context->config->{foo};
    return $self;
}

sub message {
    my $self = shift;
    return $self->context->stash->{message};
}

sub foo {
    return $foo;
}

1;

