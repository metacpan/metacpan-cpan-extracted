package TestApp2::View::JS;

use strict;
use warnings;

use parent 'Catalyst::View::JavaScript::Minifier::XS';

__PACKAGE__->config(
   path => 'sj',
);

1;
