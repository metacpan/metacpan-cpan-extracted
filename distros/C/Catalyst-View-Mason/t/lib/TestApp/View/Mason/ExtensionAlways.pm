package TestApp::View::Mason::ExtensionAlways;

use strict;
use warnings;
use base qw/Catalyst::View::Mason/;

__PACKAGE__->config(
        template_extension               => '.mas',
        always_append_template_extension => 1,
        use_match                        => 0,
);

1;
