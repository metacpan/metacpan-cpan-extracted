package TestApp::Templates::Appconfig;

use strict;
use warnings;
use Template::Declare::Tags;
use TestApp::Templates::Additional;

template test => sub {
    my ($self, $args) = @_;
    outs $args->{message};
};

template specified_template => sub {
    my ($self, $args) = @_;
    outs "I should be a $args->{param} test in ", $self->c->config->{name};
};

template test_self => sub {
    my ($self, $args) = @_;
    outs "Self is $self";
};

template test_isa => sub {
    my ($self, $args) = @_;
    outs "Self is $args->{what}" if $self->isa($args->{what});
};

template omgwtf => sub {
    die 'OMGWTF!';
};

1;
