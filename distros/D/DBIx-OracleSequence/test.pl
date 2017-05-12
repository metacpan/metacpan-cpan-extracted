# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use DBIx::OracleSequence;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use DBIx::OracleSequence;

my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';
my $dbh = DBI->connect('dbi:Oracle:', $dbuser, '');

unless($dbh) {
    warn "Unable to connect to Oracle ($DBI::errstr)\nTests skipped.\n";
    warn "Did you set ORACLE_USERID to user/password\@SID?\n";
    print "1..0\n";
    exit 0;
}

my $seq = DBIx::OracleSequence->new($dbh,'test_seq');
$seq->create;
print "order=", $seq->order, "\n";
if ($seq->order == 'N') {
  print "Sequence created\n";
  print "ok 2\n";
}
else {
  print "not ok 2\n";
}
$seq->print;

for (my $i=1; $i<10; $i++) {
  print "nextval=",$seq->nextval(),"\n";
}
if ($seq->currval() == 9) {
  print "ok 3\n";
}
else {
  print "not ok 3\n";
}

print "Sequence List: ";
$seq->printSequences;

print $seq->name, $seq->sequenceNameExists ? " exists\n" : " does not exist\n";
print "dropping ", $seq->name, "\n";
$seq->drop;
print $seq->name, $seq->sequenceNameExists ? " exists\n" : " does not exist\n";
print "Sequence should be gone now: ", $seq->print, "\n\n";

my $seq = DBIx::OracleSequence->new($dbh);
$seq->name('test2_seq');
$seq->create;
print "maxvalue=", $seq->maxvalue(3000), "\n";
print "cache=", $seq->cache(100), "\n";
print "cycle=", $seq->cycle('Y'), "\n";
print "order=", $seq->order('Y'), "\n";
print "incrementBy=", $seq->incrementBy(11), "\n";
$seq->print;
print "cycle=", $seq->cycle('N'), "\n";
print "cycle=", $seq->cycle, "\n";
$seq->print;
for (my $i=1; $i<20; $i++) {
  print "nextval=",$seq->nextval(),"\n";
}
if ($seq->currval == 209) {
  print "ok 4\n";
}
else {
  print "not ok 4\n";
}

print "Sequence List: ";
$seq->printSequences;

print $seq->name, $seq->sequenceNameExists ? " exists\n" : " does not exist\n";
print "dropping ", $seq->name, "\n";
$seq->drop;
print $seq->name, $seq->sequenceNameExists ? " exists\n" : " does not exist\n";

$dbh->disconnect;
