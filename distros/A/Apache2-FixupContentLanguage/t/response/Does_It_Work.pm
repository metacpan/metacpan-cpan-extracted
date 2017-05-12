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

sub handler {
    my $r = shift;
    plan $r, tests => 3;

    # perform subrequest which should overwrite Last-Modified
    $r->headers_in->set('Accept-Language', 'fr');
    my $subr = $r->lookup_uri("/foo.html");
    ok(defined $subr);

    my @cl = @{$r->content_languages};
    ok(@cl, "Now we have content languages");

    # make sure the header has bee nmodified
    ok(defined($cl[0]) && ($cl[0] eq 'fr'), "Header is correct");

    Apache2::Const::OK;
}

1;
