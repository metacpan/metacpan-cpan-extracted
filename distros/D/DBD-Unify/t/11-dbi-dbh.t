#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# Test if all of the documented DBI API is implemented and working OK

BEGIN { use_ok ("DBI") }

# =============================================================================

my ($schema, $dbh) = ("DBUTIL");

#eval q{ {
#    local $ENV{UNIFY};
#    $dbh = DBI->connect ("dbi:Unify:", "", "", {
#	RaiseError => 0,
#	PrintError => 0,
#	});
#    } };
#like ($DBI::errstr, qr{UNIFY' directory does not exist},	"undefined \$UNIFY");

ok ($dbh = DBI->connect ("dbi:Unify:", "", $schema), "connect");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }

# =============================================================================

ok ( DBD::Unify->driver,	"Top level driver");

# Attributes common to all handles

ok ( $dbh->{Warn},		"Warn");
ok ( $dbh->{Active},		"Active");
is ( $dbh->{Kids}, 0,		"Kids");
ok (!$dbh->{CachedKids} || 0 == keys %{$dbh->{CachedKids}}, "CachedKids");
is ( $dbh->{ActiveKids}, 0,	"ActiveKids");
ok (!$dbh->{CompatMode},	"CompatMode");

# =============================================================================

my @tables;
ok (@tables = $dbh->tables, "tables");
y/"//d for @tables;	# get_info (29) now returns "
ok ((1 == grep m/^SYS\.ACCESSIBLE_TABLES$/, @tables), "SYS.ACCESSIBLE_TABLES");
ok (@tables = $dbh->tables (undef, "SYS", "ACCESSIBLE_COLUMNS", "VIEW"), "tables (args)");
y/"//d for @tables;	# get_info (29) now returns "
ok (@tables == 1 && $tables[0] eq "SYS.ACCESSIBLE_COLUMNS", "got only one");

# =============================================================================

# Lets assume this is a default installation, and the DBA has *not* removed
# the DIRS table ;-)

ok ($dbh->do ("update DIRS set DIRNAME = 'Foo' where DIRNAME = '^#!\" //'"), "do update");
{   # Disable the warner, as the attributes are still unused
    local $SIG{__WARN__} = sub {};

    ok ($dbh->do ("update DIRS set DIRNAME = 'Foo' where DIRNAME = '^#!\" //'",
	{ uni_verbose => 1 }), "do () with 'unused' attributes");

    ok ($dbh->do ("update DIRS set DIRNAME = ? where DIRNAME = ?",
	{ uni_verbose => 1 },
	"Foo", '^#!\" //'), "do () with 'unused' params");
    }

ok ($dbh->rollback,	"rollback");
ok ($dbh->commit,	"commit");

ok ($dbh->do ("update DIRS set DIRNAME = 'Foo' where DIRNAME = '^#!\" //'"), "do () reverse");

# =============================================================================

ok ($dbh->disconnect,	"disconnect");
ok (!$dbh->{Active},	"!Active");
ok (!$dbh->ping,	"!ping");

done_testing;
