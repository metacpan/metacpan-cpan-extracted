
use strict;
use warnings;
package Test::Apache2::Layer::MapStorage;


use Apache2::Const -compile => qw(
    OK DECLINED
);
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();
use Apache2::Filter ();
use APR::Table ();

use File::Basename qw(dirname basename);
use File::Spec ();

sub handler {
    my $r = shift;

    $r->headers_out->add('X-PrevFilename' => $r->filename);

    return Apache2::Const::DECLINED;
}


1;

