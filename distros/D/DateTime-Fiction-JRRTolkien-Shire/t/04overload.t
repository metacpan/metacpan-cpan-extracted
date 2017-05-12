use strict;
use warnings;

use Test::More tests => 3;
use DateTime;
use DateTime::Fiction::JRRTolkien::Shire;

my $time = time;
my $shire1 = DateTime::Fiction::JRRTolkien::Shire->from_epoch( epoch => $time );
my $shire2 = DateTime::Fiction::JRRTolkien::Shire->from_epoch( epoch => $time + 5*86400);
my $shire3 = DateTime::Fiction::JRRTolkien::Shire->from_epoch( epoch => $time );
my $shire4 = DateTime::Fiction::JRRTolkien::Shire->new( year => 1419, month => 3, day => 25 );

ok($shire1 < $shire2);
ok($shire1 == $shire3);
is("$shire4", 'Sunday 25 Rethe 1419');
