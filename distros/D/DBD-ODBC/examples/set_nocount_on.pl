# $Id$
# shows what happens in MS SQL Server when set nocount on is set
# according to MS setting it on reduces network traffic since a count
# off the affected/selected rows is not returned to the driver.
use strict;
use warnings;
use DBI;

my $h = DBI->connect() or die $DBI::errstr;
if (defined($h->err)) {
    if ($h->err eq 0) {
	print "Warning message : ", $h->errstr, "\n";
    } elsif ($h->err eq '') {
	print "Informational message : ", $h->errstr, "\n";
    }
}
print "Out Connection String: ", $h->{odbc_out_connect_string}, "\n";

eval {
    local $h->{PrintError} = 0;
    $h->do(q/drop table nocount_test/);
};
$h->do(q/create table nocount_test (a integer)/);
my $s = $h->prepare(q/insert into nocount_test values(?)/);
foreach (1..5) {
    $s->execute($_);
}

$s = $h->prepare(q/update nocount_test set a = a + 1/);
$s->execute;
print "Rows affected: ", $s->rows, "\n";;

$s = $h->prepare(q/set nocount on;update nocount_test set a = a + 1/);
$s->execute;
print "Rows affected: ", $s->rows, "\n";;
