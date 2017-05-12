#!/usr/bin/perl -w -I./t
#
# Test the experimental odbc_getdiagrec and odbc_getdiagfield
#
use strict;
use warnings;
use DBI;
use Data::Dumper;
use Test::More;
use DBD::ODBC qw(:diags);

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;

BEGIN {
   if (!defined $ENV{DBI_DSN}) {
      plan skip_all => "DBI_DSN is undefined";
   }
}

# header fields:
#define SQL_DIAG_CURSOR_ROW_COUNT			(-1249)
#define SQL_DIAG_DYNAMIC_FUNCTION  7
#define SQL_DIAG_DYNAMIC_FUNCTION_CODE 12
#define SQL_DIAG_NUMBER            2
#define SQL_DIAG_RETURNCODE        1
#define SQL_DIAG_ROW_COUNT         3

my @hdr_fields = (SQL_DIAG_CURSOR_ROW_COUNT, SQL_DIAG_DYNAMIC_FUNCTION, SQL_DIAG_DYNAMIC_FUNCTION_CODE, SQL_DIAG_NUMBER, SQL_DIAG_RETURNCODE, SQL_DIAG_ROW_COUNT);

# record fields:
#define SQL_DIAG_CLASS_ORIGIN      8
#define SQL_DIAG_COLUMN_NUMBER				(-1247)
#define SQL_DIAG_CONNECTION_NAME  10
#define SQL_DIAG_MESSAGE_TEXT      6
#define SQL_DIAG_NATIVE            5
#define SQL_DIAG_ROW_NUMBER				(-1248)
#define SQL_DIAG_SERVER_NAME      11
#define SQL_DIAG_SQLSTATE          4
#define SQL_DIAG_SUBCLASS_ORIGIN   9

my @record_fields = (SQL_DIAG_CLASS_ORIGIN, SQL_DIAG_COLUMN_NUMBER, SQL_DIAG_CONNECTION_NAME, SQL_DIAG_MESSAGE_TEXT, SQL_DIAG_NATIVE, SQL_DIAG_ROW_NUMBER, SQL_DIAG_SERVER_NAME, SQL_DIAG_SQLSTATE, SQL_DIAG_SUBCLASS_ORIGIN);

sub get_fields {
    my ($h, $record) = @_;

    foreach (@hdr_fields, @record_fields) {
        eval {
            my $x = $h->odbc_getdiagfield($record, $_);
            note("$_ = " . ($x ? $x : 'undef') . "\n");
        };
        if ($@) {
            note("diag field $_ errored\n");
        }
    }
}

my $h = DBI->connect();
unless($h) {
   BAIL_OUT("Unable to connect to the database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}
my $dbname = $h->get_info(17); # DBI::SQL_DBMS_NAME
if ($dbname =~ /sqlite/i) {
    plan skip_all => "sqlite core dumps with this test - I can't find anywhere to report it";
}

$h->{RaiseError} = 1;
$h->{PrintError} = 0;

my ($s, @diags);

@diags = $h->odbc_getdiagrec(1);
is(scalar(@diags), 0, 'no dbh diags after successful connect') or explain(@diags);

my $ok = eval {
    $h->get_info(9999);		# should fail as there is no 9999 info value
    1;
};

ok(!$ok, "SQLGetInfo fails");
@diags = $h->odbc_getdiagrec(1);
is(scalar(@diags), 3, '   and 3 diag fields returned');
note(Data::Dumper->Dump([\@diags], [qw(diags)]));

get_fields($h, 1);

@diags = $h->odbc_getdiagrec(2);
is(scalar(@diags), 0, '   and no second record diags');

$ok = eval {
    # some drivers fail on the prepare - some don't fail until execute
    $s = $h->prepare(q/select * from table_does_not_exist/);
    $s->execute;
    1;
};
ok(!$ok, "select on non-existant table fails");
if ($s) {
    @diags = $s->odbc_getdiagrec(1);
    is(scalar(@diags), 3, '   and 3 diag fields returned');
    note(Data::Dumper->Dump([\@diags], [qw(diags)]));

    get_fields($s, 1);
}

Test::NoWarnings::had_no_warnings()
  if ($has_test_nowarnings);

done_testing();
