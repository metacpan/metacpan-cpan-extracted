use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More;

plan skip_all => 'set ATOMPUB_TEST_LIVE to enable this test'
    unless $ENV{ATOMPUB_TEST_LIVE};
plan tests => 11;

# current time is "Mon Jan 01 10:00:00 2007" in your timezone
BEGIN {
    use HTTP::Date qw(str2time);
    *CORE::GLOBAL::time = sub { str2time '2007-01-01 10:00:00' };
}

use Atompub::DateTime qw(datetime);
use DateTime;
use Time::Local;

sub diff {
    my $dt = DateTime->from_epoch(epoch => time); # in UTC
    my $tz = Atompub::DateTime::tz();             # in local time
    $tz->offset_for_datetime($dt);                # diff in sec.
}

sub tz {
    my $diff = diff();
    my $tz = sprintf "%+03d:%02d", int( $diff / 3600 ), int( ( $diff % 3600 ) / 60 );
    $tz eq '+00:00' ? 'Z' : $tz;
}

my $dt = datetime;

is $dt->epoch, 1167645600 - diff();
is $dt->iso,   '2007-01-01 10:00:00';
is $dt->w3c,   '2007-01-01T10:00:00' . tz();

like $dt->isoz, qr{^20\d\d-\d\d-\d\d \d\d:\d\d:\d\dZ$};
like $dt->w3cz, qr{^20\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$};
like $dt->str,  qr{^[a-z]{3},\s+\d{1,2}\s+[a-z]{3}\s+20\d\d\s+\d\d:\d\d:\d\d\s+GMT$}i;

is "$dt", $dt->w3c;
is 0+$dt, $dt->epoch;

my $dt2 = datetime($dt);

ok $dt = $dt2;

$dt2 = datetime($dt->epoch + 1);

ok $dt  < $dt2;
ok $dt != $dt2;
