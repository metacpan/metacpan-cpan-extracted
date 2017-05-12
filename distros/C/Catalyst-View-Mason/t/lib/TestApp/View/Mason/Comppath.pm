package TestApp::View::Mason::Comppath;

use strict;
use warnings;
use base qw/Catalyst::View::Mason/;

__PACKAGE__->config(use_match => 0);

sub get_component_path {
    return '/foo';
}

1;
