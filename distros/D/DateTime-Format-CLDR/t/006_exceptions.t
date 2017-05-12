# -*- perl -*-

# t/006_exceptions.t - check exceptions

use strict;
use warnings;
no warnings qw(once);

use Test::More tests => 19;
use Test::Exception;
use Test::Warn;

use DateTime::Format::CLDR;

my $cldr = DateTime::Format::CLDR->new();

throws_ok {
    $cldr->locale('xx');
} qr/Invalid locale (?:name or id|code or name): xx/;

throws_ok {
    $cldr->time_zone('+9999');
} qr/Invalid offset: \+9999/;

throws_ok {
    $cldr->on_error('XXX');
} qr/The value supplied to on_error must be either/;

throws_ok {
    $cldr->incomplete('XXX');
} qr/The value supplied to incomplete must be either/;

throws_ok {
    $cldr->time_zone('Europe/Absurdistan');
} qr/The timezone 'Europe\/Absurdistan' could not be loaded, or is an invalid name/;

my $datetime;

$datetime = $cldr->parse_datetime('HASE');

is($datetime,undef,'Returned undef');

$datetime = $cldr->parse_datetime('Jun 31 , 2008');

is($datetime,undef,'Returned undef');

$datetime = $cldr->parse_datetime('Xer 12 , 2008');

is($datetime,undef,'Returned undef');


my $cldr2 = DateTime::Format::CLDR->new(
    on_error    => 'croak',
    locale      => 'de_AT'
);

throws_ok {
    $cldr2->parse_datetime('HASE');
} qr/Could not get datetime for HASE/;


my $cldr3 = DateTime::Format::CLDR->new(
    on_error    => sub { die 'LAPIN' },
    locale      => 'de_AT'
);

throws_ok {
    $cldr3->parse_datetime('HASE');
} qr/LAPIN/;


my $cldr4 = DateTime::Format::CLDR->new(
    on_error    => 'croak',
    pattern     => 'dd.MM.yyy',
    locale      => 'de_AT'
);

throws_ok {
    $cldr4->parse_datetime('31.02.2009');
} qr/Could not get datetime for/;

throws_ok {
    $cldr4->parse_datetime('10.02.2009 000');
} qr/Could not get datetime for/;

throws_ok {
    $cldr4->parse_datetime('37.44.2009');
} qr/Could not get datetime for/;

throws_ok {
    $cldr4->parse_datetime('29.02.2009');
} qr/Could not get datetime for/;

like($cldr4->errmsg,qr/Could not get datetime for/,'Error message ok');

my $cldr5 = DateTime::Format::CLDR->new(
    on_error    => 'croak',
    pattern     => 'dd.MM.yyy EEEE',
    locale      => 'de_AT'
);

throws_ok {
    $cldr5->parse_datetime('02.03.2009 Mittwoch');
} qr/Datetime 'day_of_week' does not match/;

my $cldr6 = DateTime::Format::CLDR->new(
    on_error    => 'croak',
    pattern     => 'dd.MM.yyy HH:mm z',
);

warning_like {
    $cldr6->parse_datetime('02.03.2009 12:30 EST');
} qr/Ambiguous timezone/i,"Parse ambiguous timezone";

my $cldr7 = DateTime::Format::CLDR->new(
    on_error    => 'croak',
    pattern     => 'dd.MM LLLLL.yyy',
    locale      => 'de'
);

warning_like {
    $cldr7->parse_datetime('02.05 M.2009')
} qr/Expression 'M' is ambigous/,"Parse ambiguous pattern";


$cldr = DateTime::Format::CLDR->new(
    on_error=> 'undef',
    locale  => 'en',
    pattern => 'MMM d, yy eeee',
);

my $dt = $cldr->parse_datetime( 'Jan 3, 10 Friday' );

is($dt,undef,'Returned undef');