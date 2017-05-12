# -*- perl -*-

# t/005_extended.t - check extended locales

use strict;
use warnings;
no warnings qw(once);
use utf8;

use lib qw(t/lib);
use testlib;

BEGIN {
    use constant LOCALES => qw(ar en ru);
    use Test::More tests => 2 + (366 * 2 * 4 * 3) ;
}
use Test::NoWarnings;

use DateTime::Locale::Catalog;
use DateTime::TimeZone;

use_ok( 'DateTime::Format::CLDR' );

#my $time_zone = DateTime::TimeZone->new( name => 'Z' );
my $time_zone = DateTime::TimeZone->new(name => 'Europe/Vienna');

explain('Running extended tests: This may take a couple of minutes');

foreach my $localeid (LOCALES) {

    explain("Running tests for locale '$localeid'");

    my $locale = DateTime::Locale->load( $localeid );

    foreach my $pattern (qw(
        datetime_format_long
        datetime_format_full
        datetime_format_medium
        datetime_format_short)) {

        #explain("SET LOCALE: $localeid->{id} : $pattern : ".$locale->$pattern());

        my $dtf = DateTime::Format::CLDR->new(
            locale      => $locale,
            pattern     => $locale->$pattern(),
            time_zone   => $time_zone
        );

        my $dt1 = DateTime->new(
            year    => 1998,
            month   => 1,
            day     => 1,
            hour    => 12,
            minute  => 13,
            locale  => $locale,
            time_zone=> $time_zone,
            nanosecond  => 0,
        );

        my $dt2 = DateTime->new(
            year    => 2008,
            month   => 1,
            day     => 1,
            hour    => 23,
            minute  => 59,
            locale  => $locale,
            time_zone=> $time_zone,
            nanosecond  => 0,
        );

        while ($dt2->year == 2008) {
            testlib::compare($dtf,$dt1);
            testlib::compare($dtf,$dt2);
            #testlib::compare($dtf,$dt3);

            $dt1->add( days => 1 );
            $dt2->add( days => 1 );
        }
    }
}