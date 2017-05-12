use strict;
use warnings;

use Test::More;
use DBI;
use DBIx::TextIndex;


if (defined $ENV{DBIX_TEXTINDEX_DSN}) {
    plan tests => 1;
} else {
    plan skip_all => '$ENV{DBIX_TEXTINDEX_DSN} (and DBIX_TEXTINDEX_USER and DBIX_TEXTINDEX_PASS) must be set to a DBI DSN to run tests against a database.';
}

my $dbh;
eval {
    $dbh = DBI->connect($ENV{DBIX_TEXTINDEX_DSN}, $ENV{DBIX_TEXTINDEX_USER}, $ENV{DBIX_TEXTINDEX_PASS}, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
};
if ($@) {
    if (! $DBI::errstr) {
	print "Bail out! Could not connect to database: $@\n";
    } else {
	print "Bail out! Could not connect to database: $DBI::errstr\n";
    }
    exit;
}

ok( defined $dbh && $dbh->ping);
