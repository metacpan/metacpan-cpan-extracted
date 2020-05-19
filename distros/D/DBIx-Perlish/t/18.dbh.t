use warnings;
use strict;
use lib '.';
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

package DBI::db;
package good_dbh;
use vars '@ISA';
@ISA="DBI::db";
package main;

my $bad_dbh = bless {}, 'something';
eval { DBIx::Perlish->new(dbh => $bad_dbh) };
like($@||"", qr/Invalid database handle supplied/, "new with bad dbh");

my $good_dbh = bless {}, 'good_dbh';
eval { DBIx::Perlish->new(dbh => $good_dbh) };
is($@||"", "", "new with inherited dbh");

done_testing;
