use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);
use lib 't';
use MY::slurp;

# Test "Content-Type" headers
plan tests => 3, need_lwp;

# "Content-Type" with additional attributes (e.g. "charset")
charset_minified: {
    my $body = GET_BODY '/content-type/charset';
    my $min  = slurp( 't/htdocs/minified.txt' );
    chomp($min);

    ok( t_cmp($body, $min) );
}

# Missing "Content-Type" header; should decline processing and we get the
# un-minified version.  Apache, however, -will- set a default "Content-Type"
# into the response.
content_type_missing: {
    my $res  = GET '/content-type/missing';
    my $body = $res->content;
    my $orig = slurp( 't/htdocs/test.js' );

    ok( $res->content_type eq 'text/missing' );
    ok( t_cmp($body, $orig) );
}
