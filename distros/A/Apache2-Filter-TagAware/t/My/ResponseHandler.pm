package My::ResponseHandler;

use strict;
use warnings;
use Apache2::RequestRec qw();
use Apache2::RequestIO qw(); 
use Apache2::RequestUtil qw(); 
use Apache2::Log qw();
use Apache2::Const -compile => qw(OK DECLINED);
use My::slurp qw(slurp);

sub handler {
    my $r = shift;

    $r->content_type('text/html');
    my $text = slurp($r->document_root . qq[/index.html]);
    $r->print($text);

    return Apache2::Const::OK;
}

1;
