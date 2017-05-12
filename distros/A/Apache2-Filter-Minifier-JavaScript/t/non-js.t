use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);
use lib 't';
use MY::slurp;

# Make sure that non-JS files get passed through unaltered
plan tests => 1, need_lwp;

# Non-JS file should get passed through unaltered
non_js_unaltered: {
    my $body = GET_BODY '/test.txt';
    my $orig = slurp( 't/htdocs/test.txt' );
    ok( t_cmp($body, $orig) );
}
