use strict;
use warnings;

use Test::More;

BEGIN {
    if (defined $ENV{DBIX_TEXTINDEX_DSN}) {
        plan tests => 7;
    } else {
        plan skip_all => '$ENV{DBIX_TEXTINDEX_DSN} must be defined to run tests.';
    }

    use_ok qw(DBI);
    use_ok qw(DBIx::TextIndex)

}

my $TESTDATA = 'testdata/encantadas.txt';

my $dbh = DBI->connect($ENV{DBIX_TEXTINDEX_DSN}, $ENV{DBIX_TEXTINDEX_USER}, $ENV{DBIX_TEXTINDEX_PASS}, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

ok( defined $dbh && $dbh->ping, 'Connected to database' );

my $dbd = $dbh->{Driver}->{Name};

if ($dbd eq 'mysql' or $dbd eq 'SQLite' or $dbd eq 'Pg') {
    my @tables = $dbh->tables(undef, undef, 'textindex_doc', 'table');
    my $table_exists = 0;
    foreach my $table (@tables) {
	if ($table =~ m/^.*\.?[\"\`]?textindex_doc[\"\`]?$/) {
	    $table_exists = 1;
	    last;
	}
    }
    if ($table_exists) {
        ok( defined($dbh->do('DROP TABLE textindex_doc')), 'Test doc table dropped' );
    } else {
	ok(1, 'No need to drop test doc table');
    }
    ok( defined($dbh->do(<<END)), 'Created test doc table' );
CREATE TABLE textindex_doc(
doc_id INT NOT NULL PRIMARY KEY,
doc TEXT)
END

} else {
    print "Bail out! Unsupported DBD driver: $dbd\n";
}

{
    local $/ ="\n\n";

    my $sth = $dbh->prepare( qq(INSERT INTO textindex_doc (doc_id, doc) values (?, ?)) ) || die $dbh->errstr;

    open F, $TESTDATA or die "open file error $TESTDATA, $!, stopped";
    my $doc_id = 1;
    while (<F>) {
	$sth->execute($doc_id, $_) || die $dbh->errstr;
	$doc_id++;
    }
    close F;
}

ok ( (226) == $dbh->selectrow_array(qq(SELECT COUNT(*) from textindex_doc)),
    'test doc table has correct number of test documents' );

my $doc_226 =  qq("Oh, Brother Jack, as you pass by,\nAs you are now, so once was I.\nJust so game, and just so gay,\nBut now, alack, they've stopped my pay.\nNo more I peep out of my blinkers,\nHere I be -- tucked in with clinkers!"\n);

ok ( ($doc_226) eq $dbh->selectrow_array(qq(SELECT doc FROM textindex_doc where doc_id = ?), undef, 226), "doc id 226 matches expected" );

$dbh->disconnect;
