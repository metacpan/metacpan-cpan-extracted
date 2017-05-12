package TestManip::out_append;

# this test demonstrates how to write manip() callback to append new headers
# to existins headers. Here we added header 'Leech'.

use strict;
use warnings FATAL => 'all';

use base qw(Apache2::Filter::HTTPHeadersFixup);

use Apache2::RequestRec ();
use Apache2::RequestIO ();

use APR::Table ();

use Apache::TestTrace;

use Apache2::Const -compile => qw(OK M_POST);

my $key = "Leech";
my $val = "Hungry";

sub manip {
    my ($class, $ra_headers) = @_;
    # don't forget the new line!
    my $header = "$key: $val\n";
    debug "appending: [$header]";
    push @$ra_headers, $header;

    debug "returning @{[ 0+@$ra_headers ]} headers";
}

sub response {
    my $r = shift;

    my $data = $r->method_number == Apache2::Const::M_POST
        ? ModPerl::Test::read_post($r)
        : '';

    $r->content_type('text/plain');
    $r->print($data);

    return Apache2::Const::OK;
}

1;
__END__
<NoAutoConfig>
<VirtualHost TestManip::out_append>
  # must be preloaded so the FilterConnectionHandler attributes will
  # be set by the time the filter is inserted into the filter chain
  PerlModule TestManip::out_append
  PerlOutputFilterHandler TestManip::out_append
  <Location /TestManip__out_append>
     SetHandler modperl
     PerlResponseHandler TestManip::out_append::response
  </Location>
</VirtualHost>
</NoAutoConfig>
