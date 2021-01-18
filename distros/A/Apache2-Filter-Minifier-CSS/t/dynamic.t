use strict;
use warnings FATAL => 'all';
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);
use lib 't';
use File::Slurp qw(slurp);

# Test dynamically generated content
plan tests => 2, need_lwp;

# dynamic, plain text should be un-altered
dynamic_unaltered: {
    my $body = GET_BODY '/dynamic/plain';
    my $orig = slurp( 't/htdocs/test.txt' );
    ok( t_cmp($body, $orig) );
}

# dynamic, CSS should be minified
dynamic_minified: {
    my $body = GET_BODY '/dynamic/css';
    my $min  = slurp( 't/htdocs/minified.txt' );
    chomp($min);

    ok( t_cmp($body, $min) );
}
