# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package TestApp::View::TD::Main;
use strict;
use warnings;
use Template::Declare::Tags;

template action_name => sub {
    p { "This is the action_name template." };
};

template stash => sub {
    my ($self, $c) = @_;
    p { "Hello, ". $c->stash->{world} };
};

template magic_stash => sub {
    my ($self, $c) = @_;
    p { "Hello, $_{world}" };
};

template methods => sub {
    p { c->hello_world };
};

1;
