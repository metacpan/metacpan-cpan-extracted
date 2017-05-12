use strict;
BEGIN { $^W = 1 }

use Test::More qw/no_plan/;

use DateTime;
use DateTime::Format::Epoch::JD;
use DateTime::Format::Epoch::MJD;
use DateTime::Format::Epoch::NTP;
use DateTime::Format::Epoch::TJD;
use DateTime::Format::Epoch::RJD;
use DateTime::Format::Epoch::Lilian;
use DateTime::Format::Epoch::RataDie;

my $dt = DateTime->new( year => 2004, month => 8, day => 28 );

my %dates = (
    JD  =>  2453245.5,
    MJD =>    53245,
    NTP =>    3302640000,
    TJD =>    13245,
    RJD =>    53245.5,
    Lilian => 154086,
    RataDie => 731821 );

while (my ($timescale, $value) = each %dates) {
    #no strict 'refs';
    is( ("DateTime::Format::Epoch::$timescale")->format_datetime($dt),
        $value, $timescale );
    is( ("DateTime::Format::Epoch::$timescale")->new->format_datetime($dt),
        $value, $timescale );

    is( ("DateTime::Format::Epoch::$timescale")->parse_datetime($value)
           ->datetime,
        $dt->datetime, "parse $timescale" );
}
