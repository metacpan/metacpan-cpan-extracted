use strict;
BEGIN { $^W = 1 }

use Test::More tests => 4;
use DateTime;
use DateTime::Format::Roman;

for (['2003-03-01', 'I Kalends March MMIII'],
     ['2003-03-02', 'VI Nones March MMIII'],
     ['2003-03-08', 'VIII Ides March MMIII'],
     ['2000-02-24', 'VI bis Kalends March MM'],
    ){
    my ($date, $r) = @$_;

    my ($y, $m, $d) = split /-/, $date;
    my $dt = DateTime->new( year => $y, month => $m, day => $d);

    is( DateTime::Format::Roman->format_datetime( $dt ), $r, $date );;
}
