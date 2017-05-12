# -*- perl -*-

# t/014_bug_rt49605.t - check bug http://rt.cpan.org/Public/Bug/Display.html?id=49605

use strict;
use warnings;
no warnings qw(once);

use lib qw(t/lib);
use testlib;

use Test::More tests => 1+1;
use Test::NoWarnings;

use DateTime;
use DateTime::Format::CLDR;

my $fc = DateTime::Format::CLDR->new(
    pattern     => 'dd.MM.yyyy x HH:mm:ss',
    locale      => 'de_DE',
    time_zone   => 'Europe/Berlin',
);

my $dt = DateTime->new(
    year    => 2011,
    month   => 11,
    day     => 12,
    hour    => 13,
    minute  => 14,
    second  => 15,
);
$dt->set_formatter($fc);

is($dt.'','12.11.2011 x 13:14:15','DateTime formated ok');