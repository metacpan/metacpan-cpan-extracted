package MyApp::View::TT;
use strict;
use warnings;
use base qw( Catalyst::View::TT );

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    WRAPPER            => 'wrapper.tt',
);

1;
