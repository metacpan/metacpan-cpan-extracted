package TestApp::View::TT;

use strict;
use warnings;
use base 'Catalyst::View::TT';
use FindBin qw($Bin);

__PACKAGE__->config(
                TEMPLATE_EXTENSION => '.tt',
                CATALYST_VAR => 'c',
                WRAPPER => 'wrapper.tt',
            );

foreach my $dir ('', '../..') {
    if (-x "$Bin/$dir/templates") {
        __PACKAGE__->config( INCLUDE_PATH => ["$Bin/$dir/templates"] );
    }
}

1;
