# -*- perl -*-

# t/009_incomplete.t - check incomplete cldr patterns

use strict;
use warnings;
no warnings qw(once);

use Test::More tests => 7;
use Test::NoWarnings;

use DateTime::Format::CLDR;

my $dtf1 = DateTime::Format::CLDR->new(
    locale      => 'en',
    pattern     => 'yyyy.MM',
    incomplete  => 1,
);
my $dt1 = $dtf1->parse_datetime('2008.12');
is ($dt1->dmy('.'),'01.12.2008','Missing date has been filled');

my $dtf2 = DateTime::Format::CLDR->new(
    locale      => 'en',
    pattern     => 'yyyy.MM',
    incomplete  => 'incomplete',
);
my $dt2 = $dtf2->parse_datetime('2008.12');
isa_ok($dt2,'DateTime::Incomplete','Return DateTime::Incomplete object');
is($dt2->year,2008,'Incomplete date year');
is($dt2->month,12,'Incomplete date mont');
ok(! $dt2->has_day,'Incomplete date day missing');

my $dtf3 = DateTime::Format::CLDR->new(
    locale      => 'en',
    pattern     => 'yyyy.MM',
    incomplete  => sub {
        my ($self,%datetime) = @_;
        $datetime{day} = 15;
        return %datetime;
    },
);
my $dt3 = $dtf3->parse_datetime('2008.12');
is ($dt3->dmy('.'),'15.12.2008','Missing date has been filled');