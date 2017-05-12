#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Test::More;

use DBIx::Librarian;
use Data::Library::ManyPerFile;

use Log::Channel;

if ($ENV{TEST_LOGGING}) {
    use Log::Dispatch::File;
    my $filename = "log.out";
    my $file = Log::Dispatch::File->new( name      => 'file1',
					 min_level => 'info',
					 filename  => $filename,
					 mode      => 'write' );
    dispatch Log::Channel "DBIx::Librarian", $file;
    dispatch Log::Channel "Data::Library", $file;
} else {
    disable Log::Channel "Data::Library";
    disable Log::Channel "DBIx::Librarian";
}

Log::Channel->commandeer("DBIx::Librarian");
Log::Channel->commandeer("Data::Library");

$ENV{DBI_DSN}="dbi:mysql:test";

my $data = {};

######################################################################

my $dbi_user = $ENV{DBI_USER} || "";
my $dbi_pass = $ENV{DBI_PASS} || "";

# Erect test tables
my $rc = system "mysql -v -D test -u$dbi_user -p$dbi_pass < tests/bugdb.ddl";
if ($?) {
    plan skip_all => "Unable to connect to mysql.  Either mysql is not installed, or you need to set DBI_USER or DBI_PASS.  Skipping all tests.";
}

plan tests => 34;

my $dblbn = new DBIx::Librarian ({
				  LIB => ["tests"],
				 });

# test series with default archiver
runtest();

$dblbn->disconnect;

my $archiver = new Data::Library::ManyPerFile({
					       LIB => ["tests"],
					       EXTENSION => "msql",
					      });
$dblbn = new DBIx::Librarian ({
			       ARCHIVER => $archiver,
			       MAXSELECTROWS => 100,
			      });

# test series with ManyPerFile archiver
runtest();

$dblbn->disconnect;

# Dismantle test tables
system ("echo 'drop table BUG' | mysql -D test -p$ENV{DBI_PASS}") and die;

exit;

sub runtest {

my @toc = $dblbn->{SQL}->toc;
ok (scalar(@toc) == 7, "toc");

######################################################################
# DELETE to prepare for test scenario

eval { $dblbn->execute("t_delete", $data); };
ok (!$@, "delete");

######################################################################
# test prepare

eval { $dblbn->prepare("t_insert_bind") };
ok (!$@, "successful prepare");

eval { $dblbn->prepare("t_no_such_query",
		       "t_select_bug") };
ok ($@, "successful prepare");

######################################################################
# INSERT with no bind variable
# SELECT check to verify that one row was inserted

my @results;
eval { @results = $dblbn->execute("t_insert", $data); };

ok($data->{bugid} == 5, "insert, no bind variables");
ok($results[0] == 2
   && $results[1]->[0] == 1
   && $results[1]->[1] == 1, "rowcounts");


# force disconnect to make sure Librarian reconnects correctly
$dblbn->{DBH}->disconnect;

######################################################################
# INSERT with bind variables
# SELECT check to verify that one row was inserted

$data->{groupset} = 17;
$data->{assigned_to} = 9;
$data->{product} = "Perl";
$data->{testnode}->{product_name} = "Perl";
#$data->{product} = [ "foo" ];

eval { $dblbn->execute("t_insert_bind", $data); };

ok($data->{bugid} == 7, "insert, with bind variables");

######################################################################
# multi-column SELECT

eval { $dblbn->execute("t_select_row"); };
ok($@, "Missing target data reference");

$data->{groupset} = 42;

eval { $dblbn->execute("t_select_row", $data); };

ok($data->{bugid} == 5, "single-row select");

eval { $dblbn->execute("t_select_row2", $data); };

ok(defined $data->{foo}, "single-row select with structure");
ok($data->{foo}->{bugid} == 5, "single-row select with structure");

######################################################################
# multi-row SELECT

eval { $dblbn->execute("t_select_all", $data); };

ok(scalar(@{$data->{bug}}) == 2, "multi-row select");

######################################################################
# repeat SELECT

my $i = 0;
foreach my $bug (@{$data->{bug}}) {
    eval { $dblbn->execute("t_select_bug", $bug); };
    $i++ if length $bug->{product} > 0;
}
ok($i == 2, "fetching rows from sub-level of data");

######################################################################
# try an non-existent query

eval { $dblbn->execute("t_does_not_exist", $data) };
ok($@, "t_does_not_exist not found");

ok (! $dblbn->can("t_does_not_exist"), "cannot");
ok ($dblbn->can("t_select_bug"), "can");

######################################################################

eval { $dblbn->execute("t_select_all"); };
ok ($@, "missing data");

######################################################################
######################################################################

}
