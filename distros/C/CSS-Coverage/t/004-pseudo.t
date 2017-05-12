use strict;
use warnings;
use Test::More;
use CSS::Coverage;

my @documents = (
    \q{<html><body><a href="foo">Hello <em>world</em>!</a></body></html>},
);

my $report = CSS::Coverage->new(
    css       => \q[
        a { color: blue }
        a:link { color: blue }
        a:hover { color: red }
        a:visited { color: purple }
        a:active { color: green }
        a:focus { color: yellow }
    ],
    documents => \@documents,
)->check;

is_deeply([$report->unmatched_selectors], [], "all selectors matched");

done_testing;

