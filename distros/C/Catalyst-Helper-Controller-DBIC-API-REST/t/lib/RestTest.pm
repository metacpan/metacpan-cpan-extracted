package # Hide from PAUSE
    RestTest;

use strict;
use warnings;

use Catalyst;

our $VERSION = '0.01';

__PACKAGE__->config( name => 'RestTest' );

__PACKAGE__->setup;

1;
