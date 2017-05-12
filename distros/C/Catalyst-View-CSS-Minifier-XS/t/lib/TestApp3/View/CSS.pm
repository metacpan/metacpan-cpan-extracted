package TestApp3::View::CSS;

use strict;
use warnings;

use parent 'Catalyst::View::CSS::Minifier::XS';

__PACKAGE__->config(
   subinclude => 1,
);

1;
