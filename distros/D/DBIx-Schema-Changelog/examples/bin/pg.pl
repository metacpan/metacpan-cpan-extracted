#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../../lib";

use strict;
use warnings;
use DBI;
use DBIx::Schema::Changelog;

my $dbh = DBI->connect( "dbi:Pg:dbname=league;host=127.0.0.1", "league", "league" );
DBIx::Schema::Changelog->new( dbh => $dbh, db_driver => 'Pg' )->read( $FindBin::Bin . '/../changelog' );