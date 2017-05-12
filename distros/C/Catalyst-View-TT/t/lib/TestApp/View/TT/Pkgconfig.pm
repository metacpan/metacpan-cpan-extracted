package TestApp::View::TT::Pkgconfig;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    PRE_CHOMP          => 1,
    POST_CHOMP         => 1,
    TEMPLATE_EXTENSION => '.tt',
);

1;
