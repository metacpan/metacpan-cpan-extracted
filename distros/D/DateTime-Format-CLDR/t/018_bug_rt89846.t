# -*- perl -*-

# t/018_bug_rt89846.t - check bug http://rt.cpan.org/Public/Bug/Display.html?id=89846

use strict;
use warnings;
no warnings qw(once);

use lib qw(t/lib);
use testlib;

use Test::More tests => 4+1;
use Test::Exception;
use Test::NoWarnings;

use DateTime;
use DateTime::Format::CLDR;

my $fc = DateTime::Format::CLDR->new(
    pattern     => 'yyyy.MM.dd kk:mm:ss',
    time_zone   => 'Europe/Madrid',
    on_error    => 'croak',
);

is($fc->parse_datetime('2013.07.21 23:00:00')->iso8601,'2013-07-21T23:00:00','23:00:00 parsed ok');
is($fc->parse_datetime('2013.07.21 24:00:00')->iso8601,'2013-07-21T00:00:00','24:00:00 parsed ok');
is($fc->parse_datetime('2013.07.21 24:30:00')->iso8601,'2013-07-21T00:30:00','24:30:00 parsed ok');
is($fc->parse_datetime('2013.07.22 01:00:00')->iso8601,'2013-07-22T01:00:00','01:00:00 parsed ok');