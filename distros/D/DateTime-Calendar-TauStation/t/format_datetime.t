use strict;
use warnings;
use Test::More tests => 2;
use DateTime::Format::TauStation;

my @gct = (
    '000.00/00:000 GCT',
    '198.15/03:973 GCT',
);

for my $gct_string (@gct) {
    my $dt = DateTime::Format::TauStation->parse_datetime($gct_string);

    is(
        DateTime::Format::TauStation->format_datetime($dt),
        $gct_string,
        "format $gct_string",
    );
}
