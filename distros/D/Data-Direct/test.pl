# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::Direct;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

eval '
use DBD::CSV;
$csv = 1;
';

unless ($csv) {
    print "Skipping test on this platform...\n";
    exit;
}

eval {

use DBI;
$dbh = DBI->connect('dbi:CSV:');

unlink "demo1" if (-e "demo1");

$dbh->do(<<EOM);
CREATE TABLE demo1 (
	id INT,
	ego REAL,
	superego REAL
)
EOM


$sth = $dbh->prepare("INSERT INTO demo1 VALUES (?, ?, ?)");
	
foreach (1 .. 20) {
    $sth->execute($_, rand, -1);
}

undef $dbh;

$d = new Data::Direct('dbi:CSV:', '', '', 'demo1');
$d->simplebind('main');

while (!$d->eof) {
    $superego = $ego;
    $d->update;
    $d->next;
}

$d->flush;

$dbh = DBI->connect('dbi:CSV:');
$sth = $dbh->prepare("SELECT * FROM demo1 WHERE ego <> superego");
$sth->execute;

die if ($sth->rows);

$worked = 1;

};

print $worked ? "ok 2\n" : "not ok 2\n";

unlink "demo1";
