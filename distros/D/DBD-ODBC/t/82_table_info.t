#!/usr/bin/perl -w -I./t
#
# Test type_info
#
use strict;
use warnings;
use DBI;
use Test::More;
use Data::Dumper;
use DBI::Const::GetInfoType;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;

my $dbh;

BEGIN {
   if (!defined $ENV{DBI_DSN}) {
      plan skip_all => "DBI_DSN is undefined";
   }
}

END {
    if ($dbh) {
        local $dbh->{PrintWarn} = 0;
        local $dbh->{PrintError} = 0;
        $dbh->do(q/drop table PERL_DBD_DROP_ME/);
    }
};

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;

$dbh->do(q/create table PERL_DBD_DROP_ME (a char(10))/);

if ($dbh->get_info($GetInfoType{SQL_CATALOG_NAME}) ne 'N') {

    # test type_info('%','','') which should return catalogs only
    my $s = $dbh->table_info('%', '', '');
    my $r = $s->fetchall_arrayref;
    if ($r && scalar(@$r)) {    # assuming we get something back
        my $pass = 1;
        foreach my $row (@$r) {
            if (!defined($row->[0])) {
                $pass = 0;
                diag("Catalog is not defined");
            }

            if (defined($row->[1])) {
                $pass = 0;
                diag("Schema is defined as $row->[1]");
            }

            if (defined($row->[2])) {
                $pass = 0;
                diag("Table is defined as $row->[2]");
            }
        }
        ok($pass, "catalogs only") or diag(Dumper($r));
    }
}

if ($dbh->get_info($GetInfoType{SQL_SCHEMA_USAGE}) != 0) {
    # test type_info('','%','') which should return schema only
    my $s = $dbh->table_info('', '%', '');
    my $r = $s->fetchall_arrayref;
    if ($r && scalar(@$r)) {    # assuming we get something back
        my $pass = 1;
        foreach my $row (@$r) {
            if (defined($row->[0])) {
                $pass = 0;
                diag("Catalog is defined as $row->[0]");
            }

            if (!defined($row->[1])) {
                $pass = 0;
                diag("Schema is not defined");
            }

            if (defined($row->[2])) {
                $pass = 0;
                diag("Table is defined as $row->[2]");
            }
        }
        ok($pass, "schema only") or diag(Dumper($r));
    }
}

{
    # test type_info() - returns tables
    my $s = $dbh->table_info(undef, undef, 'PERL_DBD_DROP_ME');
    my $r = $s->fetchall_arrayref;
    ok(scalar(@$r) > 0, 'table found');

    if ($r && scalar(@$r)) {    # assuming we get something back
        my $pass = 0;
        foreach my $row (@$r) {
            $pass = 1;
        }
        ok($pass, "table only") or diag(Dumper($r));
    }
}

# test type_info('','','', '%')  which should return table types only

SKIP: {
    skip "SQLite is known to fail the next test because catalog, schema and table are returned as '' instead of undef", 1
        if ($dbh->get_info($GetInfoType{SQL_DRIVER_NAME}) =~ /sqlite/);
    my $s = $dbh->table_info('', '', '', '%');
    my $r = $s->fetchall_arrayref;
    if ($r && scalar(@$r)) {    # assuming we get something back
        my $pass = 1;
        foreach my $row (@$r) {
            if (defined($row->[0])) {
                $pass = 0;
                diag("Catalog is defined as $row->[0]");
            }

            if (defined($row->[1])) {
                $pass = 0;
                diag("Schema is defined as $row->[1]");
            }

            if (defined($row->[2])) {
                $pass = 0;
                diag("Table is defined as $row->[2]");
            }

            if (!defined($row->[3])) {
                $pass = 0;
                diag("table type is not defined");
            }
        }
        ok($pass, "table type only") or diag(Dumper($r));
    }
};

Test::NoWarnings::had_no_warnings()
  if ($has_test_nowarnings);

done_testing();
