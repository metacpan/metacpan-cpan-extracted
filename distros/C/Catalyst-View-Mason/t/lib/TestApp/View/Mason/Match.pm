package TestApp::View::Mason::Match;

use strict;
use warnings;
use base qw/Catalyst::View::Mason/;

__PACKAGE__->config(
    use_match => 1,
);

1;
