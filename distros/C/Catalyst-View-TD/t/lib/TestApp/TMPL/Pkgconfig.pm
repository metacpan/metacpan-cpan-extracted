package TestApp::TMPL::Pkgconfig;

use strict;
use Template::Declare::Tags;
use base 'Template::Declare::Catalyst';

template test => sub {
    my ($self, $msg, $args) = @_;
    outs $args->{message} eq 'override' ? $msg : $args->{message};
};

1;
