use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);
use lib 't';
use MY::slurp;

# Test non-JS responses when we've supplemented MIME-Types list
plan tests => 2, need_lwp;

# non-JS responses are filtered when we add a single new MIME-Type
single_mimetype: {
    my $body  = GET_BODY '/mimetypes/single';
    my $min   = slurp('t/htdocs/minified.txt');
    chomp($min);

    ok( t_cmp($body, $min) );
}

# non-JS responses are filtered when we add multiple new MIME-Types
multiple_mimetypes: {
    my $body  = GET_BODY '/mimetypes/multiple';
    my $min   = slurp('t/htdocs/minified.txt');
    chomp($min);

    ok( t_cmp($body, $min) );
}
