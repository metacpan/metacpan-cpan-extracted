package Does_It_Work;

use warnings FATAL => 'all';
use strict;

#use Apache2::RequestRec ();
#use Apache2::RequestIO  ();
use Apache2::SubRequest ();
use Apache2::Util       ();

use Apache2::Const  -compile => qw(OK);

use APR::Table  ();

use Apache::Test qw(-withtestmore);

use HTTP::Date  ();

sub handler {
    my $r = shift;
    plan $r, tests => 5;

    # set header for epoch 0;
    my $lm = Apache2::Util::ht_time($r->pool, 0);
    $r->headers_out->set('Last-Modified', $lm);

    # make sure the header exists
    my $hdr = $r->headers_out->get('Last-Modified');
    ok(defined $hdr, "Last-Modified: $hdr");

    # make sure the header is epoch 0
    my $time = HTTP::Date::str2time($hdr);
    ok($time == 0, "time: $time");

    # perform subrequest which should overwrite Last-Modified
    my $subr = $r->lookup_uri("/index.html");
    ok(defined $subr);

    # reacquire purportedly modified header
    $hdr = $r->headers_out->get('Last-Modified');
    ok(defined $hdr, "Last-Modified: $hdr");

    # make sure the header has bee nmodified
    $time = HTTP::Date::str2time($hdr);
    ok($time > 0, "time: $time");

    Apache2::Const::OK;
}

1;
