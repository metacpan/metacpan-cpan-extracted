package TestApp3::View::JS;

use strict;
use warnings;

use parent 'Catalyst::View::JavaScript::Minifier::XS';

__PACKAGE__->config(
   subinclude => 1,
);

1;
