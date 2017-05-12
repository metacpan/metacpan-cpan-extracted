# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package TestApp::View::Test;
use strict;
use warnings;
use base qw(Catalyst::Component::ACCEPT_CONTEXT Catalyst::View);

sub message {
    my $self = shift;
    return $self->context->stash->{message};
}

1;

