#!/usr/bin/perl
#
# Name:
#	split-xml.pl.

use strict;
use warnings;

use DBIx::Admin::BackupRestore;

# -----------------------------------------------

my($file_name) = shift || die("Usage: perl split-xml.pl all-tables.xml");

# Options skip_schema, skip_tables and transform_tablenames are really only
# meaningful when moving data from Postgres to MySQL, and are otherwise harmless.

DBIx::Admin::BackupRestore -> new
(
	output_dir_name			=> '.',
	skip_schema				=> ['information_schema', 'pg_catalog'],
	skip_tables				=> ['log', 'sessions'],
	transform_tablenames	=> 1,
	verbose					=> 1
) -> split($file_name);
