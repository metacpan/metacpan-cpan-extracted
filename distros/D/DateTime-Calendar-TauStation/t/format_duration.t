use strict;
use warnings;
use Test::More tests => 3;
use DateTime::Format::TauStation;

# don't test per-second accuracy - many test report failures

my @durations = (
    [ 'D4.3/02:001 GCT' => qr| ^ D 4 \. 3 / 02 : [0-9]{3} [ ] GCT \z |x ],
    [ 'D3/02:001 GCT'   => qr| ^ D      3 / 02 : [0-9]{3} [ ] GCT \z |x ],
    [ 'D/02:001 GCT'    => qr| ^ D        / 02 : [0-9]{3} [ ] GCT \z |x ],
);

for my $duration (@durations) {
    my ( $duration_string, $regex ) = @$duration;

    my $dur = DateTime::Format::TauStation->parse_duration($duration_string);

    like(
        DateTime::Format::TauStation->format_duration($dur),
        $regex,
        "format $duration_string",
    );
}
