package TestApp::View::Mason::Pkgconfig;

use strict;
use warnings;
use base 'Catalyst::View::Mason';

__PACKAGE__->config(
        allow_globals => [qw/$foo @bar/],
        use_match     => 0,
);

if ($::use_path_class) {
    __PACKAGE__->config(
            comp_root => TestApp->path_to('root'),
            data_dir => TestApp->path_to('root', 'var'),
    );
}

1;
