package # Hide from PAUSE
  StompTestApp;
use Moose;
use Catalyst::Runtime '5.80003';

use Catalyst qw/
                ConfigLoader
	       /;
use namespace::autoclean;

extends 'Catalyst';

__PACKAGE__->config( name => 'StompTestApp' );
__PACKAGE__->setup;
__PACKAGE__->meta->make_immutable;

