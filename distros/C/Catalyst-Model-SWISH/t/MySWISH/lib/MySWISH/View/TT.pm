package MySWISH::View::TT;
use strict;
use base qw( Catalyst::View::TT );
use Template::Plugin::Handy 'install';

__PACKAGE__->config( TEMPLATE_EXTENSION => '.tt', );

1;
