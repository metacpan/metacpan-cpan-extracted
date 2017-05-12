use strict;
BEGIN { $^W = 1 }

use Test::More tests => 4;
use DateTime;
use DateTime::Format::Roman;

my $f = DateTime::Format::Roman->new(pattern =>
    '%d:%f:%m:%y:%B:%b:%Od:%od:%1f:%O1D');

for (['2003-03-01', '1:Kal:3:2003:March:Mar:I:i:K:K'],
     ['2003-03-02', '6:Non:3:2003:March:Mar:VI:vi:N:VI N'],
     ['2003-03-08', '8:Id:3:2003:March:Mar:VIII:viii:Id:VIII Id'],
     ['2000-02-24', '6bis:Kal:3:2000:March:Mar:VI bis:vi bis:K:VI bis K'],
    ){
    my ($date, $r) = @$_;

    my ($y, $m, $d) = split /-/, $date;
    my $dt = DateTime->new( year => $y, month => $m, day => $d);

    is( $f->format_datetime( $dt ), $r, $date );;
}
