use strict;
use warnings;
use Test::More tests => 3;
use DateTime::Format::TauStation;

my @durations = (
    'D4.3/02:001 GCT',
    'D3/02:001 GCT',
    'D/02:001 GCT',
);

for my $duration_string (@durations) {
    my $dur = DateTime::Format::TauStation->parse_duration($duration_string);

    is(
        DateTime::Format::TauStation->format_duration($dur),
        $duration_string,
        "format $duration_string",
    );
}
