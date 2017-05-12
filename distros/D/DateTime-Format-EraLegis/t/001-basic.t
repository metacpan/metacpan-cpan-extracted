#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Encode qw(encode_utf8);
use DateTime;
use DateTime::Format::ISO8601;
use DBD::SQLite;

BEGIN {
    use_ok('DateTime::Format::EraLegis');
}

binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my $ephem = DateTime::Format::EraLegis::Ephem::DBI->new(
    ephem_db => './t/test.sqlite3' );

my $dtf;
$dtf = DateTime::Format::EraLegis->new(
    ephem => $ephem,
    style => DateTime::Format::EraLegis::Style->new(lang=>'symbol'),
);
is scalar @{$dtf->style->signs}, 12, 'Have twelve signs';

my $tstamp = '2012-12-03T23:00:00';

my $iso = DateTime::Format::ISO8601->new;
my $dt = $iso->parse_datetime($tstamp);
$dt->set_formatter( $dtf );
my $out = ''.$dt;
is $out, '☉ in 12° ♐ : ☽ in 10° ♌ : ☽ : ⅠⅤⅹⅹ',
    'Basic rendering';

$dtf = DateTime::Format::EraLegis->new(
    ephem => $ephem,
    style => DateTime::Format::EraLegis::Style->new(
        lang=>'latin', show_dow=>0, show_year=>1) );
is $dtf->format_datetime($dt),
    '☉ in 12° Sagittarii : ☽ in 10° Leonis : Anno ⅠⅤⅹⅹ æræ legis',
    'Basic rendering';

$dtf = DateTime::Format::EraLegis->new(
    ephem => $ephem,
    style => DateTime::Format::EraLegis::Style->new(
        lang=>'latin', show_terse=>1, show_dow=>1, show_year=>0) );
is $dtf->format_datetime($dt),
    '☉ 12° Sagittarii : ☽ 10° Leonis : dies Lunae',
    'Basic rendering';

my @edges = (
    [ '2012-12-31T00:00:00', 4, 20 ],
    [ '2013-01-02T00:00:00', 4, 20 ],
    [ '2013-03-19T00:00:00', 4, 20 ],
    [ '2013-03-22T00:00:00', 4, 21 ],
    [ '2013-04-02T00:00:00', 4, 21 ],
    [ '2013-12-31T00:00:00', 4, 21 ],
    [ '2014-01-02T00:00:00', 4, 21 ],
    [ '2014-03-16T00:00:00', 4, 21 ],
    [ '2014-03-25T00:00:00', 5, 0 ],
    [ '2014-04-01T00:00:00', 5, 0 ],
    );

$dtf = DateTime::Format::EraLegis->new(
    ephem => $ephem,
    style => DateTime::Format::EraLegis::Style->new(
        lang=>'symbol', show_terse=>1, show_dow=>0, show_year=>1) );
for (@edges) {
    my $dt = $iso->parse_datetime($_->[0]);
    my $raw = $dtf->format_datetime($dt, 'raw');
    #warn "$_->[0] -> $raw->{plain}";
    is $raw->{year}[0], $_->[1], '1st docosade edge case';
    is $raw->{year}[1], $_->[2], '2nd docosade edge case';
}



done_testing;
