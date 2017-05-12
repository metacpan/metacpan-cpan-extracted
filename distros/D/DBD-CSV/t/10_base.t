#!/usr/bin/perl

# Test whether the driver can be installed

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok ("DBI");
    use_ok ("SQL::Statement");
    }

ok ($SQL::Statement::VERSION, "SQL::Statement::Version $SQL::Statement::VERSION");

do "t/lib.pl";

my $nano = $ENV{DBI_SQL_NANO};
defined $nano or $nano = "not set";
diag ("Showing relevant versions (DBI_SQL_NANO = $nano)");
diag ("Using DBI            version $DBI::VERSION");
diag ("Using DBD::File      version $DBD::File::VERSION");
diag ("Using SQL::Statement version $SQL::Statement::VERSION");
diag ("Using Text::CSV_XS   version $Text::CSV_XS::VERSION");

ok (my $switch = DBI->internal, "DBI->internal");
is (ref $switch, "DBI::dr", "Driver class");

# This is a special case. install_driver should not normally be used.
ok (my $drh = DBI->install_driver ("CSV"), "Install driver");

is (ref $drh, "DBI::dr", "Driver class installed");

ok ($drh->{Version}, "Driver version $drh->{Version}");

my $dbh = DBI->connect ("dbi:CSV:");
my $csv_version_info = $dbh->csv_versions ();
ok ($csv_version_info, "csv_versions");
diag ($csv_version_info);

done_testing ();
