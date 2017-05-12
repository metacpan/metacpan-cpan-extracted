#!/usr/bin/perl

use strict;
use warnings;

use BerkeleyDB;

my $min_version = 4.0;

warn "BerkeleyDB version is $BerkeleyDB::VERSION, library $BerkeleyDB::db_version\n";

die "OS unsupported\nYour version of the Berkeley DB library (not the module) is too old ($BerkeleyDB::db_version, we need $min_version)\n" unless $BerkeleyDB::db_version >= $min_version;

