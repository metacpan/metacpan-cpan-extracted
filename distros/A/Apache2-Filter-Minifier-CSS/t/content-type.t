use strict;
use warnings FATAL => 'all';
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);
use lib 't';
use File::Slurp qw(slurp);

# Test "Content-Type" headers
plan tests => 2, need_lwp;

# "Content-Type" with additional attributes (e.g. "charset")
charset_minified: {
    my $body = GET_BODY '/content-type/charset';
    my $min  = slurp( 't/htdocs/minified.txt' );
    chomp($min);

    ok( t_cmp($body, $min) );
}

# Missing "Content-Type" header; should decline processing and we get the
# un-minified version.
content_type_missing: {
    my $res  = GET '/content-type/missing';
    my $body = $res->content;
    my $orig = slurp( 't/htdocs/test.css' );

    ok( t_cmp($body, $orig) );
}
