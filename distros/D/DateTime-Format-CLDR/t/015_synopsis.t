# -*- perl -*-

# t/015_bug_synopsis.t - check examples in synopsis

use strict;
use warnings;
no warnings qw(once);

use lib qw(t/lib);
use testlib;

use Test::More tests => 10+1;
use Test::NoWarnings;

use DateTime;
use DateTime::Format::CLDR;


# Basic example
my $cldr1 = DateTime::Format::CLDR->new(
    pattern     => 'HH:mm:ss',
    locale      => 'de_AT',
    time_zone   => 'Europe/Vienna',
);

isa_ok($cldr1,'DateTime::Format::CLDR');
my $dt1 = $cldr1->parse_datetime('23:16:42');
isa_ok($dt1,'DateTime');
is($cldr1->format_datetime($dt1),'23:16:42','Time formated ok');

# Get pattern from selected locale
# pattern is taken from 'date_format_medium' in DateTime::Locale::de_AT
my $cldr2 = DateTime::Format::CLDR->new(
    locale      => 'de_AT',
);

my $dt2 = $cldr2->parse_datetime('23.11.2007');
isa_ok($dt2,'DateTime');
is($dt2->iso8601,'2007-11-23T00:00:00','DateTime formated ok');

# Croak when things go wrong
my $cldr3 = DateTime::Format::CLDR->new(
    locale      => 'de_AT',
    on_error    => 'croak',
);
isa_ok($cldr3,'DateTime::Format::CLDR');
eval {
    $cldr3->parse_datetime('23.33.2007');
};
like($@,qr/23\.33\.2007/,'Error message ok');

# Use DateTime::Locale
my $locale4 = DateTime::Locale->load('en_GB');
my $cldr4 = DateTime::Format::CLDR->new(
    pattern     => 'd MMM y HH:mm:ss',
    locale      => $locale4,
);

isa_ok($cldr4,'DateTime::Format::CLDR');
my $dt4 = $cldr4->parse_datetime('22 Dec 1995 09:05:02');
isa_ok($dt4,'DateTime');
is($dt4->iso8601,'1995-12-22T09:05:02','Time parsed ok');