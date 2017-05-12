#!perl -w
# vim: ft=perl
#
#   $Id: 40blobs.t 11244 2008-05-11 15:13:10Z capttofu $
#
#   This is a test for correct handling of BLOBS; namely $dbh->quote
#   is expected to work correctly.
#


use DBI ();
use Test::More;
use vars qw($table $test_dsn $test_user $test_password);
use lib '.', 't';
require 'lib.pl';

sub ShowBlob($) {
    my ($blob) = @_;
    for ($i = 0;  $i < 8;  $i++) {
        if (defined($blob)  &&  length($blob) > $i) {
            $b = substr($blob, $i*32);
        }
        else {
            $b = "";
        }
        printf("%08lx %s\n", $i*32, unpack("H64", $b));
    }
}

my $dbh;
eval {$dbh = DBI->connect($test_dsn, $test_user, $test_password,
  { RaiseError => 1, AutoCommit => 1}) or ServerError() ;};

if ($@) {
    plan skip_all => "ERROR: $DBI::errstr. Can't continue test";
}
plan tests => 14;

my $size= 128;

ok $dbh->do("DROP TABLE IF EXISTS $table"), "Drop table if exists $table";

$dbh->{mysql_enable_utf8}=1;

my $create = <<EOT;
CREATE TABLE $table (
    id INT NOT NULL DEFAULT 0,
    name BLOB)
EOT

ok ($dbh->do($create));

my ($b, $blob) = ("","");

for ($j = 0;  $j < 256;  $j++) {
    $b .= chr($j);
}
for ($i = 0;  $i < $size;  $i++) {
    $blob .= $b;
}
#   Insert a row into the test table.......
my $query = "INSERT INTO $table VALUES(1, ?)";
ok ($sth = $dbh->prepare($query));

ok ($sth->execute($blob));

#   Now, try SELECT'ing the row out.
ok ($sth = $dbh->prepare("SELECT * FROM $table WHERE id = 1"));

ok ($sth->execute);

ok ($row = $sth->fetchrow_arrayref);

ok defined($row), "row returned defined";

is @$row, 2, "records from $table returned 2";

is $$row[0], 1, 'id set to 1';
my $blob_out = $$row[1];

print $fh $blob_out;
close $fh;
print $fh2 $blob;
close $fh2;
cmp_ok byte_string($blob_out, 'eq', byte_string($blob), 'blob set equal to blob returned';

ShowBlob($blob), ShowBlob(defined($blob_out) ? $blob_out : "");

ok ($sth->finish);

$dbh->{AutoCommit} = 1;
ok $dbh->do("DROP TABLE $table"), "Drop table $table";

ok $dbh->disconnect;
