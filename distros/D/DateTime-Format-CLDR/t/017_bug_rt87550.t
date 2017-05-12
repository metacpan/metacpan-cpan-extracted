# -*- perl -*-

# t/017_bug_rt87550.t - check bug http://rt.cpan.org/Public/Bug/Display.html?id=87550

use strict;
use warnings;
no warnings qw(once);

use lib qw(t/lib);
use testlib;

use Test::More tests => 3+1;
use Test::Exception;
use Test::NoWarnings;

use DateTime;
use DateTime::Format::CLDR;

my $fc = DateTime::Format::CLDR->new(
    pattern     => 'yyyy.MM.dd HH:mm:ss',
    time_zone   => 'Europe/Madrid',
    on_error    => 'croak',
);

is($fc->parse_datetime('2013.07.21 24:00:00')->iso8601,'2013-07-22T00:00:00','24:00:00 parsed ok');
is($fc->parse_datetime('2013.07.31 24:00:00')->iso8601,'2013-08-01T00:00:00','24:00:00 parsed ok');

throws_ok {
    my $dt = $fc->parse_datetime('2013.07.21 24:01:00');
} qr/Invalid 24-hour notation/;