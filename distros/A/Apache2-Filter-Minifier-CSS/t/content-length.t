use strict;
use warnings FATAL => 'all';
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Apache::Test;
use Apache::TestRequest;

# Test "Content-Length" logic
plan tests => 2, need_lwp;

# plain text is handled by default-handler, which sets Content-Length
default_handler: {
    my $res = GET '/raw/test.txt';
    ok( $res->content_length, -s 't/htdocs/test.txt' );
}

# CSS is handled by the filter, which removes Content-Length
minified_handler: {
    my $res = GET '/raw/test.css';
    ok( !$res->content_length );
}
