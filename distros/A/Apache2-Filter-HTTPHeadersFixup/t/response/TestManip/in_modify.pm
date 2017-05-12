package TestManip::in_modify;

# this test demonstrates how to write manip() callback to modify existing
# headers. Here we modify the header 'Sign-Here'.

use strict;
use warnings FATAL => 'all';

use base qw(Apache2::Filter::HTTPHeadersFixup);

use Apache2::RequestRec ();
use Apache2::RequestIO ();

use APR::Table ();

use Apache::TestTrace;

use Apache2::Const -compile => qw(OK M_POST);

my $key = "Sign-Here";

sub manip {
    my ($class, $ra_headers) = @_;

    debug "processing @{[ 0+@$ra_headers ]} headers";
    for (@$ra_headers) {
        s/^($key).*/$1: DigSig/;
    }
}

sub response {
    my $r = shift;

    my $data = $r->method_number == Apache2::Const::M_POST
        ? ModPerl::Test::read_post($r)
        : '';

    $r->content_type('text/plain');
    $r->print($data);

    # copy the input header to output headers
    $r->headers_out->set($key => $r->headers_in->get($key));

    return Apache2::Const::OK;
}

1;
__END__
<NoAutoConfig>
<VirtualHost TestManip::in_modify>
  # must be preloaded so the FilterConnectionHandler attributes will
  # be set by the time the filter is inserted into the filter chain
  PerlModule TestManip::in_modify
  PerlInputFilterHandler TestManip::in_modify
  <Location /TestManip__in_modify>
     SetHandler modperl
     PerlResponseHandler TestManip::in_modify::response
  </Location>
</VirtualHost>
</NoAutoConfig>
