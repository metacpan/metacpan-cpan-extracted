#!/usr/bin/env perl
#
# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: deploy_magetab_db.pl 351 2010-09-03 10:58:15Z tfrayner $

use strict;
use warnings;

use Bio::MAGETAB::Util::Persistence;
use Bio::MAGETAB;

use Getopt::Long;

# Process command-line options.
my $dsn;
GetOptions(
    "d|dsn=s" => \$dsn,
);
unless ( $dsn ) {
    print <<"USAGE";

Usage: $0 -d <DSN or SQLite database filename>

USAGE

    exit 255;
}

# Allow SQLite users to just give the database name.
unless ( $dsn =~ /\A dbi: /ixms ) {
    $dsn = "dbi:SQLite:$dsn";
}       

# Some basic sanity tests.
my ( $dbtype, $dbname ) = ( $dsn =~ /\A dbi : ([^:]+) : ([^:]+) /ixms );
unless ( $dbtype && $dbname ) {
    die(qq{Error: Unable to parse DSN "$dsn".\n});
}
if ( $dbtype eq 'SQLite' && -e $dbname ) {
    die(qq{Error: SQLite database file "$dbname" already exists.\n});
}

# Deploy the database schema.
my $db = Bio::MAGETAB::Util::Persistence->new( dbparams => [ $dsn ] );
$db->deploy();
