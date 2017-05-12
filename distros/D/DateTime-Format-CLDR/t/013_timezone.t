# -*- perl -*-

# t/013_timezone.t - Check support for timezones

use strict;
use warnings;
no warnings qw(once);

use Test::More tests => 1 + (5 * 4 * 24) + (24 * 5);
use Test::NoWarnings;

use lib qw(t/lib);
use testlib;

use DateTime;
use DateTime::Format::CLDR;

my @timezones = qw(
    Africa/Casablanca
    America/Argentina/Buenos_Aires
    America/Vancouver
    Asia/Kabul
    Europe/Vienna
);

my @patterns = qw(
    Z
    ZZZZ
    z
    zzzz
);

#z,v,V => WET
#zzzz,vvvv,VVVV => Africa/Casablanca
#Z => +0000
#ZZZZ => WET+0000

foreach my $timezone (@timezones) {
    explain("Running tests for timezone '$timezone'");

    foreach my $pattern (@patterns) {
        my $dtf = DateTime::Format::CLDR->new(
            locale      => 'en_US',
            pattern     => 'dd.MM.yyy HH:mm ' . $pattern,
            on_error    => 'croak',
        );

        my $dt = DateTime->new(
            year        => 2009,
            month       => 5,
            day         => 10,
            hour        => 0,
            minute      => 0,
            time_zone   => $timezone,
        );

        while ($dt->dmy('.') eq '10.05.2009') {
            my $parsed = testlib::compare($dtf,$dt,"Timezone $timezone with pattern $pattern ok");
            $dt->add( hours => 1, minutes => 2 );
            if ($pattern eq 'zzzz') {
                my $timezone_class = $timezone;
                $timezone_class =~ s/\//::/g;
                isa_ok($parsed->time_zone,'DateTime::TimeZone::'.$timezone_class,'Correct timezone set');
            }
        }
    }
}