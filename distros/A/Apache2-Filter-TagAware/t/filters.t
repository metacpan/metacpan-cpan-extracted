use strict;
use warnings FATAL => 'all';
use lib 't';
use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);
use My::slurp qw(slurp);

# Test "Content-Length" logic
plan tests => 7, need_lwp;

# plain text is handled by default-handler, which sets Content-Length
no_filter: {
    my $res = GET '/index.html';
    my $text = slurp(qq[t/htdocs/index.html]);
    ok( t_cmp($res->content, $text, "non-adjusted filter" ));
}

with_filter_50: {
    my $res = GET '/50/index.html';
    my $text = slurp(qq[t/htdocs/index.50.html]);
    ok( t_cmp($res->content, $text, "50 char sup! filter" ));
}

with_filter_200: {
    my $res = GET '/200/index.html';
    my $text = slurp(qq[t/htdocs/index.200.html]);
    ok( t_cmp($res->content, $text, "200 char sup! filter" ));
}

with_filter_2048: {
    my $res = GET '/2048/index.html';
    my $text = slurp(qq[t/htdocs/index.2048.html]);
    ok( t_cmp($res->content, $text, "2048 char sup! filter" ));
}

with_filter_50: {
    my $res = GET '/perl50/index.html';
    my $text = slurp(qq[t/htdocs/index.50.html]);
    ok( t_cmp($res->content, $text, "50 char sup! filter" ));
}

with_filter_200: {
    my $res = GET '/perl200/index.html';
    my $text = slurp(qq[t/htdocs/index.200.html]);
    ok( t_cmp($res->content, $text, "200 char sup! filter" ));
}

with_filter_2048: {
    my $res = GET '/perl2048/index.html';
    my $text = slurp(qq[t/htdocs/index.2048.html]);
    ok( t_cmp($res->content, $text, "2048 char sup! filter" ));
}
