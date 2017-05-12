#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use DBI;
use DBIx::Admin::TableInfo 3.02;

# ---------------------

my($attr)              = {};
$$attr{sqlite_unicode} = 1 if ($ENV{DBI_DSN} =~ /SQLite/i);
my($dbh)               = DBI -> connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, $attr);
my($info)              = DBIx::Admin::TableInfo -> new(dbh => $dbh) -> info;

$dbh -> do('pragma foreign_keys = on') if ($ENV{DBI_DSN} =~ /SQLite/i);

for my $table (qw/pricing_plans receipts)
{
	print "Foreign keys for $table: \n", Dumper($$info{$table}{foreign_keys}), "\n";
}
