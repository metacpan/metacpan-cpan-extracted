# $Id$
#
use strict;
use warnings;

use Test::More;

use DateTime::Format::DBI;

eval "use DBI;";
plan skip_all => "DBI required for real database test" if $@;

eval "use DBD::SQLite;";
plan skip_all => "DBD::SQLite required for real database test" if $@;

eval "use DateTime::Format::SQLite;";
plan skip_all => "DateTime::Format::SQLite required for real SQLite test" if $@;

plan tests => 1;

my $file = "sql$$.tmp";
my $dbh = DBI->connect("dbi:SQLite:dbname=$file","","");

isa_ok(DateTime::Format::DBI->new($dbh), 'DateTime::Format::SQLite');

unlink $file;
