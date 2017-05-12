package TestApp::View::Mason::Extension;

use strict;
use warnings;
use base qw/Catalyst::View::Mason/;

__PACKAGE__->config(
        template_extension => '.mas',
        use_match          => 0,
);

1;
