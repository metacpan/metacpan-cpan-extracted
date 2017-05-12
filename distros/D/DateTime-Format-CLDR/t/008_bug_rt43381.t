# -*- perl -*-

# t/007_bug_rt43381.t - check bug http://rt.cpan.org/Public/Bug/Display.html?id=43381

use strict;
use warnings;
no warnings qw(once);

use lib qw(t/lib);
use testlib;

use Test::More tests => (2 * 60 * 24 ) +2;
use Test::NoWarnings;

use_ok( 'DateTime::Format::CLDR' );

my $dtf = DateTime::Format::CLDR->new(
    locale      => 'en_US',
    pattern     => 'HH:mm:ss',
    on_error    => 'croak',
);

my $dt = DateTime->new(
    year    => 1,
    month   => 1,
    day     => 1,
    hour    => 0,
    minute  => 0,
    second  => 0,
    locale  => 'en_US',
    nanosecond  => 0,
);

while ($dt->dmy('.') eq '01.01.0001') {
    testlib::compare($dtf,$dt);
    $dt->add( seconds => 30 );
}