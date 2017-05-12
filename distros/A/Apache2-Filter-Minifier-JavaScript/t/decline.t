use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);
use lib 't';
use MY::slurp;

# Test non-JS responses still have other filters applied
plan tests => 1, need_lwp;

# non-JS response is processed by other filters
other_filters: {
    my $body  = GET_BODY '/decline_uc';
    my $upper = uc( slurp('t/htdocs/test.txt') );
    ok( t_cmp($body, $upper) );
}
