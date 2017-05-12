use strict;
use warnings;

package ImgTestApp;

use FindBin qw/$Bin/;
use Path::Class;

use Catalyst qw/ Images /;

__PACKAGE__->config( home => dir( $Bin )->parent->subdir(qw/t data/) );


__PACKAGE__->config( images => {
    paths => [
        __PACKAGE__->path_to( "/" ),
        __PACKAGE__->path_to( "one" ),
        __PACKAGE__->path_to( "two" ),
        __PACKAGE__->path_to( "three" ),
    ],

    uri_base => __PACKAGE__->path_to("/"),
});

__PACKAGE__->setup;

1;
