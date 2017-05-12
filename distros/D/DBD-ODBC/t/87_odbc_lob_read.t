#!/usr/bin/perl -w -I./t
use strict;
use warnings;
use DBI qw(:sql_types);
use Test::More;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;

my $dbh;
my $bind_string = "frederickfrederick";

BEGIN {
   if (!defined $ENV{DBI_DSN}) {
      plan skip_all => "DBI_DSN is undefined";
   }
}

my $not_sql_server;

END {
    if ($dbh) {
        local $dbh->{PrintError} = 0;
        local $dbh->{PrintWarn} = 0;
        eval {
            $dbh->do(q/drop table DBD_ODBC_LOB_TEST/);
        };
    }
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings && !$not_sql_server);

    done_testing();
}

my $h = DBI->connect();
unless($h) {
   BAIL_OUT("Unable to connect to the database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}
$h->{RaiseError} = 0;
$h->{PrintError} = 0;

my $dbname = $h->get_info(17); # DBI::SQL_DBMS_NAME
unless ($dbname =~ /Microsoft SQL Server/i) {
    $not_sql_server = 1;
    note("Not MS SQL Server");
    plan skip_all => "Not MS SQL Server";
}

eval {
    $h->do(q/drop table DBD_ODBC_LOB_TEST/);
};

eval {
    $h->do(q/create table DBD_ODBC_LOB_TEST(a image)/);
} or BAIL_OUT("Failed to create test table $@");

my $s = $h->prepare(q/insert into DBD_ODBC_LOB_TEST (a) values(?)/);
ok($s, "Created test table");

$s->bind_param(1, $bind_string, {TYPE => SQL_BINARY});
ok($s->execute, "inserted test data") or BAIL_OUT($DBI::errstr);

ok($s = $h->prepare(q/select a from DBD_ODBC_LOB_TEST/),
   "preparing select") or BAIL_OUT("cannot select test data $DBI::errstr");
ok($s->execute, "executing select") or BAIL_OUT("execute $DBI::errstr");

ok($s->bind_col(1, undef, {TreatAsLOB => 1}), "binding");

ok($s->fetch, "fetching");

getit($s, SQL_BINARY);
$s->execute;
$s->fetch;
getit($s, SQL_BINARY);

sub getit{
    my ($s, $type) = @_;

    my $total = 0;
    my $first = 1;
    my $fetched = '';

    my $len;
    while($len = $s->odbc_lob_read(1, \my $x, 8, {TYPE => $type})) {
        if ($first) {
            if ($type == SQL_BINARY) {
                is($len, 8, "correct chunk size");
            } else {
                is($len, 7, "correct chunk size");
            }
        }
        #diag("len=$len, x=$x, ", length($x));
        $total += $len;
        $first = 0;
        $fetched .= $x;
    }
    is($len, 0, "0 at end");

    is($total, length($bind_string), "received correct amount of bytes");
    is($fetched, $bind_string, "data correct");

    my $x;
    $len = $s->odbc_lob_read(1, \$x, 8);
    is($len, 0, "0 at end after another read");

}
$s->finish;


$h->disconnect;

