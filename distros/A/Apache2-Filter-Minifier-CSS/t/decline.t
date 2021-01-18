use strict;
use warnings FATAL => 'all';
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);
use lib 't';
use File::Slurp qw(slurp);

# Test non-CSS responses still have other filters applied
plan tests => 1, need_lwp;

# non-CSS response is processed by other filters
other_filters: {
    my $body  = GET_BODY '/decline_uc';
    my $upper = uc( slurp('t/htdocs/test.txt') );
    ok( t_cmp($body, $upper) );
}
