#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../../lib";

use strict;
use warnings;
use DBI;
use DBIx::Schema::Changelog;
my $source_db     = 'source_db';
my $source_user   = "source_user";
my $source_pass   = "source_pass";
my $source_host   = '127.0.0.1';
my $source_driver = 'Pg';

my $target_db     = 'target_db';
my $target_user   = "target_user";
my $target_pass   = "target_pass";
my $target_host   = '127.0.0.1';
my $target_driver = 'Pg';

my $dir = '/path/to/dir';
my $dbh = DBI->connect( "dbi:$source_driver:dbname=$source_db;host=$source_host", $source_user, $source_pass );
DBIx::Schema::Changelog->new( dbh => $dbh, db_driver => $source_driver )->write($dir);
$dbh->disconnect;

$dbh = DBI->connect( "dbi:$target_driver:dbname=$target_db;host=$target_host", $target_user, $target_pass );
DBIx::Schema::Changelog->new( dbh => $dbh, db_driver => $target_driver )->read($dir);
$dbh->disconnect;
