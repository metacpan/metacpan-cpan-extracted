package My::TestFilter200;

use strict;
use warnings;
use Apache2::Filter::TagAware qw();
use Apache2::RequestRec qw();
use Apache2::Log qw();
use APR::Table qw();
use Apache2::Const -compile => qw(OK DECLINED);

sub handler {
    my $f = Apache2::Filter::TagAware->new(shift);
    my $r = $f->r;

    my $ctx = $f->ctx;

    if (!$ctx){
        $ctx = {};
        $r->headers_out->unset('Content-Length');
        $ctx->{'fixed_headers'} = 1;
        $r->warn('unset cl');
        $f->ctx($ctx);
    }

    while ($f->read(my $buffer, 200)) {
        # filter stuff here
        $f->print($buffer . qq[ sup! ]);
    }

    return Apache2::Const::OK;
}

1;
