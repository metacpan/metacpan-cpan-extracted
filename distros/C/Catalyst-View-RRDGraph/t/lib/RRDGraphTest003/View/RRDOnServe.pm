package RRDGraphTest003::View::RRDOnServe;

use strict;
use base 'Catalyst::View::RRDGraph';

__PACKAGE__->config(
  'ON_ERROR_SERVE' => 'error_image.png', #ERRORIMAGEPNG
);

1;
