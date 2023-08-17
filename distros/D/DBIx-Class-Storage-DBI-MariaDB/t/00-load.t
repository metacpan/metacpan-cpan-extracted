#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('DBIx::Class::Storage::DBI::MariaDB') || print "Bail out!\n";
}

diag(
"Testing DBIx::Class::Storage::DBI::MariaDB $DBIx::Class::Storage::DBI::MariaDB::VERSION, Perl $], $^X"
);
