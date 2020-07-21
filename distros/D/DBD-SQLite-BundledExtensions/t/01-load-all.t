#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use DBI;
use File::Find;
use DBD::SQLite::BundledExtensions;
use Alien::DBD::SQLite::BundledExtensions;

use Test::Simple tests => 10;

my $dbh=DBI->connect('dbi:SQLite:dbname=:memory:',
    "",
    "",
    { RaiseError => 1, PrintError => 0 }
);

ok(defined $dbh, "Can create SQLite in memory DB");

for (@Alien::DBD::SQLite::BundledExtensions::extensions) {
    ok(DBD::SQLite::BundledExtensions->_load_extension($dbh, $_), "Load extension $_");
}