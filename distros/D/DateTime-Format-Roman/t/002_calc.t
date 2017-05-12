use strict;
BEGIN { $^W = 1 }

use Test::More tests => 13;
use DateTime;
use DateTime::Format::Roman;

my $f = DateTime::Format::Roman->new(pattern => ['%d', '%f', '%m', '%y']);

isa_ok($f, 'DateTime::Format::Roman' );

$" = ':';

     # date,           day,    fixed, month, year
for (['2003-03-01',      1, 'Kal',     3, 2003],
     ['2003-03-02',      6, 'Non',     3, 2003],
     ['2003-03-06',      2, 'Non',     3, 2003],
     ['2003-03-07',      1, 'Non',     3, 2003],
     ['2003-03-08',      8,  'Id',     3, 2003],
     ['2003-03-15',      1,  'Id',     3, 2003],
     ['2003-03-16',     17, 'Kal',     4, 2003],
     ['2003-03-31',      2, 'Kal',     4, 2003],
     ['2003-12-14',     19, 'Kal',     1, 2004],
     ['2000-02-23',      7, 'Kal',     3, 2000],
     ['2000-02-24', '6bis', 'Kal',     3, 2000],
     ['2000-02-25',      6, 'Kal',     3, 2000],
    ){
    my ($date, @r) = @$_;

    my ($y, $m, $d) = split /-/, $date;
    my $dt = DateTime->new( year => $y, month => $m, day => $d);

    my @f = $f->format_datetime( $dt );
    is( "@f", "@r", $date );
}
