use strict;
use warnings;
use Test::More tests => 2;
use DateTime::Format::TauStation;

# don't test per-second accuracy - many test report failures

my @gct = (
    [ '000.00/00:000 GCT' => qr| ^ 000 \. 00 / 00 : [0-9]{3} [ ] GCT \z |x ],
    [ '198.15/03:973 GCT' => qr| ^ 198 \. 15 / 03 : [0-9]{3} [ ] GCT \z |x ],
);

for my $datetime (@gct) {
    my ( $gct_string, $regex ) = @$datetime;

    my $dt = DateTime::Format::TauStation->parse_datetime($gct_string);

    like(
        DateTime::Format::TauStation->format_datetime($dt),
        $regex,
        "format $gct_string",
    );
}
