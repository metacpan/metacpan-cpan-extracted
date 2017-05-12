
use strict;
use warnings;
package Test::Apache2::Layer::RemoveArgs;


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

    my $old = $r->args("");

    $r->headers_out->add('X-RemovedArgs' => $old);

    return Apache2::Const::DECLINED;
}


1;

