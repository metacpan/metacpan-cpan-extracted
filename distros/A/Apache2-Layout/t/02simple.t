#!perl -w
use strict;
use Test::More;

BEGIN {
    if (!eval "use Apache::Test qw(:withtestmore); 1;") {
        plan skip_all => "No Apache::Test";
    }
    if (!eval "use Apache::TestUtil qw(t_cmp); 1;") {
        plan skip_all => "No Apache::TestUtil ($@)";
    }
}

use Apache::TestRequest;

my @urls = qw(
/simple/simple.html
/cgi/test.pl
);

plan tests => 6 * scalar(@urls);

foreach my $url (@urls) {
my $content = GET $url;

ok $content;
ok t_cmp(200, $content->code, "Check that the request was OK");
my $html = $content->content;

ok t_cmp($html, qr[This is the css],    "LayoutCSS found");
ok t_cmp($html, qr[This is the header], "LayoutHeader found");
ok t_cmp($html, qr[This is the footer], "LayoutFooter found");
ok t_cmp($html,
         qr[matched \d+ times out of \d+ over \d+ reads and \d+ passes],
         "LayoutDebug/LayoutComment found");

}
