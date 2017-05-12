use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestRequest;

# Test "Content-Length" logic
plan tests => 2, need_lwp;

# plain text is handled by default-handler, which sets Content-Length
default_handler: {
    my $res = GET '/raw/test.txt';
    ok( $res->content_length, -s 't/htdocs/test.txt' );
}

# JS is handled by the filter, which removes Content-Length
minified_handler: {
    my $res = GET '/raw/test.js';
    ok( !$res->content_length );
}
