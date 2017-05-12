#!/usr/bin/perl -w
use strict;
use Test::More;
use DBI;

if ($^O !~ /Win32/i) {
    plan skip_all => "DBD::WMI only works on Win32 so far";
} else {
    plan tests => 1;
};

my $dbh = DBI->connect('dbi:WMI:');
isa_ok $dbh, 'DBI::db';
