#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;
use DBIx::ResultSet::Connector;
use DateTime;

my $connector = DBIx::ResultSet->connect( 'dbi:SQLite:dbname=t/test.db', '', '' );

is(
    $connector->format_date(DateTime->new(year=>2005, month=>9, day=>23)),
    '2005-09-23',
    'format_date produced expected result',
);

done_testing;
