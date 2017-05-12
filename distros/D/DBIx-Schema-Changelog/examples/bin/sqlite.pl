#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../../lib";

use strict;
use warnings;
use DBI;
use DBIx::Schema::Changelog;

my $dbh = DBI->connect( "dbi:SQLite:database=league.sqlite" );
DBIx::Schema::Changelog->new( dbh => $dbh)->read( $FindBin::Bin . '/../changelog' );