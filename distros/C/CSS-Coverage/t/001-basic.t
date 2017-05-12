use strict;
use warnings;
use Test::More;
use CSS::Coverage;

my @documents = (
    \"<html><body><p>Hello <em>world</em>!</p></body></html>",
);

my $report = CSS::Coverage->new(
    css       => \"p em {}",
    documents => \@documents,
)->check;

is_deeply([$report->unmatched_selectors], [], "all selectors matched");

$report = CSS::Coverage->new(
    css       => \"p strong {}",
    documents => \@documents,
)->check;

is_deeply([$report->unmatched_selectors], ["p strong"], "`p strong` did not match");

done_testing;
