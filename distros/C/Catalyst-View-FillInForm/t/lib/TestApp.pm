package # Hide from PAUSE
    TestApp;
use strict;
use warnings;

use Catalyst;

__PACKAGE__->config( default_view => 'TT' );

__PACKAGE__->setup;

1;
