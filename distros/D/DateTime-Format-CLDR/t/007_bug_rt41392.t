# -*- perl -*-

# t/007_bug_rt41392.t - check bug http://rt.cpan.org/Public/Bug/Display.html?id=41392

use strict;
use warnings;
no warnings qw(once);

use lib qw(t/lib);
use testlib;

use Test::More tests => 366 + 1;
use Test::NoWarnings;

use DateTime::Format::CLDR;

my $dtf = DateTime::Format::CLDR->new(
    locale      => 'en_US',
    pattern     => 'yyyyMMddHH'
);

my $dt = DateTime->new(
    year    => 2008,
    month   => 1,
    day     => 1,
    hour    => 12,
    minute  => 0,
    locale  => 'en_US',
    nanosecond  => 0,
);

while ($dt->year == 2008) {
    testlib::compare($dtf,$dt);
    $dt->add( days => 1 );
}