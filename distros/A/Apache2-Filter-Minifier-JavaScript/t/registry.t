use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);
use lib 't';
use MY::slurp;

# Test filtered ModPerl::Registry output
plan tests => 4, need_lwp;

# MP::Registry, plain text should be un-altered
registry_unaltered: {
    my $res  = GET '/perl-bin/plain.pl';
    my $body = $res->content;
    my $orig = slurp('t/htdocs/test.txt');

    ok( $res->content_type eq 'text/plain' );
    ok( t_cmp($body, $orig) );
}

# MP::Registry, JS should be minified
registry_minified: {
    my $res  = GET '/perl-bin/js.pl';
    my $body = $res->content;
    my $min  = slurp('t/htdocs/minified.txt');
    chomp($min);

    ok( $res->content_type eq 'text/javascript' );
    ok( t_cmp($body, $min) );
}
