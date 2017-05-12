package MySWISH::Model::SWISH;
use strict;
use base qw( Catalyst::Model::SWISH );

__PACKAGE__->config( debug => $ENV{CATALYST_DEBUG}, );

1;
