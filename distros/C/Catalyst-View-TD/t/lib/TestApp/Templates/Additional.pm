package TestApp::Templates::Additional;

use strict;
use warnings;
use Template::Declare::Tags;
use base 'Template::Declare';

template testclass => sub {
    my ($self, $args) = @_;
    outs "From Additional: $args->{message}";
};

template test => sub {
    my ($self, $args) = @_;
    outs "From Additional: $args->{message}";
};

1;
