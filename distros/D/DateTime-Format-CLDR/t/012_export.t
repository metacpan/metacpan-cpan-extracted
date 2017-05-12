# -*- perl -*-

# t/012_export.t - Check exported functions

use strict;
use warnings;
no warnings qw(once);

use Test::More tests => 1 + 2;
use Test::NoWarnings;

use DateTime;
use DateTime::Format::CLDR qw(cldr_format cldr_parse);

my $datetime = DateTime->new(
    locale  => 'en',
    day     => 27,
    month   => 3,
    year    => 1979,
);

is(cldr_format('dd.MMMM.yyy',$datetime),'27.March.1979','Can format');
is(cldr_parse('dd.MMMM.yyy','27.March.1979','en'),$datetime,'Can parse');