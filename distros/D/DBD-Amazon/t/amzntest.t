use strict;
use warnings;
use vars qw($testnum $loaded);
BEGIN { my $tests = 14; $^W= 1; $| = 1; print "1..$tests\n"; }
#END {print "not ok $testnum\n" unless $loaded;}

use DBI;
use DBD::Amazon;
use SQL::Amazon::Parser;
use SQL::Amazon::Statement;
use SQL::Amazon::Functions;
use SQL::Amazon::ReqFactory;
use SQL::Amazon::Spool;
use SQL::Amazon::StorageEngine;
use SQL::Amazon::Request::Request;
use SQL::Amazon::Request::ItemLookup;
use SQL::Amazon::Request::ItemSearch;
use SQL::Amazon::Tables::Table;
use SQL::Amazon::Tables::Books;
use SQL::Amazon::Tables::BrowseNodes;
use SQL::Amazon::Tables::CustomerReviews;
use SQL::Amazon::Tables::EditorialReviews;
use SQL::Amazon::Tables::ListManiaLists;
use SQL::Amazon::Tables::Merchants;
use SQL::Amazon::Tables::Offers;
use SQL::Amazon::Tables::SimilarProducts;
use SQL::Amazon::Tables::SysSchema;

my $row;
$testnum = 1;
my $id = $ENV{DBD_AMZN_USER};

unless ($id) {
	print "not ok 1 Connect failed: No Amazon ID defined\n\t(did you forget to set the DBD_AMZN_USER environment variable ?)\n";
	print "skipping $_ no connection\n"
		foreach (2..13);
	exit 1;
}

my $dbh = DBI->connect('dbi:Amazon:', $id );

unless ($dbh) {
	print "not ok 1 Connect failed: ", $DBI::errstr, "\n";
	print "skipping $_ no connection\n"
		foreach (2..13);
	exit 1;
}

print "ok 1 Connect OK\n";
#
#	SysSchema: Test 1
#
my $testname = 'SysSchema';
$testnum++;
my $sth = $dbh->table_info();
print "not ok $testnum $testname failed: ", $dbh->errstr, "\n"
	unless $sth;

if ($sth) {
while ($row = $sth->fetchrow_arrayref) {
	foreach (0..$#$row) {
		$row->[$_] = 'NULL' 
			unless defined $row->[$_];
	}
}
print "ok $testnum SysSchema OK\n";
}
#
#	ItemLookup: Test 1
#
$testnum++;
$testname = 'Specific ItemLookup';
$sth = $dbh->prepare(
"SELECT B.PublicationDate AS PubDate,
		B.ListPriceAmt AS Price,
		B.SalesRank AS SalesRank,
		B.AverageRating AS AvgStars,
		'Title: ' || B.Title || '<br>\n' ||
		'Author(s): ' || B.Authors || '<br>\n' ||
		'Publisher: ' || B.Publisher || '<br>\n' ||
		'ASIN: ' || B.ASIN || '<br>\n' ||
		'Price: ' || B.ListPriceAmt || '<br>\n' AS ProductDetail,
		B.DetailPageURL AS URL,
		COALESCE(B.MediumImageURL, 'http://www.visubuy.com/noimgavail.png') AS Image
	FROM Books B JOIN Offers F
	WHERE B.ASIN = '1565926994' 
		AND F.ASIN = B.ASIN
		AND F.Condition = 'New'
	ORDER BY SalesRank DESC, AvgStars DESC
	LIMIT 100");

print "not ok $testnum $testname failed: ", $dbh->errstr, "\n"
	unless $sth;

exec_and_display($sth, $testname, $testnum)
	if $sth;
#
#	ItemLookup: Test 2
#
#	fetch entries for the following books:
#		'1565926994',	-- DBI
#		'0596000278',	-- The Camel
#		'0764537504',	-- for dummies
#		'0201419750',	-- effectively
#		'1884777791'	-- OO perl
#
$testnum++;
$testname = 'Multiple ItemLookup';
$sth = $dbh->prepare(
"SELECT B.PublicationDate AS PubDate,
		B.ListPriceAmt AS Price,
		B.SalesRank,
		B.AverageRating AS AvgStars,
		'Title: ' || B.Title || '<br>\n' ||
		'Author(s): ' || B.Authors || '<br>\n' ||
		'Publisher: ' || B.Publisher || '<br>\n' ||
		'ASIN: ' || B.ASIN || '<br>\n' ||
		'Price: ' || B.ListPriceAmt || '<br>\n' AS ProductDetail,
		B.DetailPageURL,
		COALESCE(B.MediumImageURL, 'http://www.visubuy.com/noimgavail.png') AS Image
	FROM Books B JOIN Offers F
	WHERE B.ASIN IN (
		'1565926994',	-- DBI
		'0596000278',	-- The Camel
		'0764537504',	-- for dummies
		'0201419750',	-- effectively
		'1884777791'	-- OO perl
		)
		AND B.ASIN = F.ASIN
		AND F.Condition = 'New'
		AND AvgStars > 3
	ORDER BY B.Title ASC
	LIMIT 100");

print "not ok $testnum $testname failed:  ", $dbh->errstr, "\n"
	unless $sth;

exec_and_display($sth, $testname, $testnum)
	if $sth;
#
#	ItemSearch: Test 1
#
$testnum++;
$testname = 'Simple ItemSearch';
$sth = $dbh->prepare(
"SELECT PublicationDate AS PubDate,
		ListPriceAmt AS Price,
		SalesRank,
		AverageRating AS AvgStars,
		'Title: ' || Title || '<br>\n' ||
		'Author(s): ' || Authors || '<br>\n' ||
		'Publisher: ' || Publisher || '<br>\n' ||
		'ASIN: ' || ASIN || '<br>\n' ||
		'Price: ' || ListPriceAmt || '<br>\n' AS ProductDetail,
		DetailPageURL,
		COALESCE(MediumImageURL, 'http://www.visubuy.com/noimgavail.png') AS Image
	FROM Books
	WHERE PubDate > '1995-01-01'
		AND MATCHES ALL ('perl', 'dbi')
		AND Price < 100.00
	ORDER BY SalesRank DESC, AvgStars DESC
	LIMIT 100");

print "not ok $testnum $testname failed:  ", $dbh->errstr, "\n"
	unless $sth;

exec_and_display($sth, $testname, $testnum)
	if $sth;
#
#	ItemSearch: Test 2:
#	test dnf xform
#	NOTE!!!! We tried using Medium and Small
#	results here, but they don't return Offer
#	info, hence our join returns no rows, and
#	we get no results <sigh/>
#	so time to test LEFT JOINs!
#	Furthermore, Small doesn't return publication date,
#	so we need a better coalesce function
#	*AND* some fields in the detail concat often are
#	NULL, which causes us to return NULL details,
#	so we need more coalesces
#
$testname = 'Complex ItemSearch';
foreach ('Large', 'Medium', 'Small') {
$testnum++;

$sth = $dbh->prepare(
"SELECT COALESCE(B.PublicationDate, '****-**-**') AS PubDate,
		B.ListPriceAmt AS Price,
		B.SalesRank AS SalesRank,
		B.AverageRating AS AvgStars,
		'Title: ' || COALESCE(B.Title, '*Unknown*') || '<br>\n' ||
		'Author(s): ' || COALESCE(B.Authors, '*Unknown*') || '<br>\n' ||
		'Publisher: ' || COALESCE(B.Publisher, '*Unknown*') || '<br>\n' ||
		'ASIN: ' || COALESCE(B.ASIN, '*Unknown*') || '<br>\n' ||
		'Price: ' || COALESCE(B.ListPriceAmt, '*Unknown*') || '<br>\n' AS ProductDetail,
		B.DetailPageURL,
		COALESCE(B.MediumImageURL, 'http://www.visubuy.com/noimgavail.png') AS Image
	FROM Books B LEFT OUTER JOIN Offers F
		ON B.ASIN = F.ASIN
	WHERE COALESCE(B.PublicationDate, '2005-12-31') > '1995-01-01'
		AND (MATCHES ALL('perl', 'dbi') OR
			MATCHES ALL('java', 'jdbc'))
		AND Price < 100.00
		AND F.Condition = 'New'
	ORDER BY SalesRank DESC, AvgStars DESC
	LIMIT 100", { amzn_resp_group => $_ });

print "not ok $testnum $_ $testname failed:  ", $dbh->errstr, "\n"
	unless $sth;

exec_and_display($sth, "$_ $testname", $testnum)
	if $sth;
}
#
#	ItemSearch: Test 3:
#	test power search xform
#	also test respo groups
#	NOTE that we need to coalesce publicationdate
#	and price, since Small doesn't return values
#	for those fields, and if we apply an IS [NOT] NULL
#	test on price, it generates a dup request
#	Eventually, we'll have a smarter query plan generator
#
$testname = 'Implicit Power ItemSearch';
foreach ('Large', 'Medium', 'Small') {
$testnum++;

$sth = $dbh->prepare(
"SELECT COALESCE(PublicationDate, '2005-01-01') AS PubDate,
		COALESCE(ListPriceAmt, 0.00) AS Price,
		SalesRank,
		AverageRating AS AvgStars,
		'Title: ' || Title || '<br>\n' ||
		'Author(s): ' || Authors || '<br>\n' ||
		'Publisher: ' || Publisher || '<br>\n' ||
		'ASIN: ' || ASIN || '<br>\n' ||
		'Price: ' || COALESCE(ListPriceAmt, 0.00) || '<br>\n' AS ProductDetail,
		DetailPageURL,
		COALESCE(MediumImageURL, 'http://www.visubuy.com/noimgavail.png') AS Image
	FROM Books
	WHERE PubDate > '1999-01-01'
		AND MATCHES ANY('perl', 'java')
		AND Price < 100.00
	ORDER BY SalesRank DESC, AvgStars DESC
	LIMIT 100", { amzn_resp_group => $_ });

print "not ok $testnum $_ $testname failed:  ", $dbh->errstr, "\n"
	unless $sth;

exec_and_display($sth, "$_ $testname", $testnum)
	if $sth;
}
#
#	ItemSearch: Test 4:
#	test explicit power search
#
$testnum++;
$testname = 'Explicit Power ItemSearch';
$sth = $dbh->prepare(
"
/* lets add some comments for cleaning up
 *
 */
SELECT PublicationDate AS PubDate,
		ListPriceAmt AS Price,
		SalesRank,
		AverageRating AS AvgStars,
		'Title: ' || Title || '<br>\n' ||
		'Author(s): ' || Authors || '<br>\n' ||
		'Publisher: ' || Publisher || '<br>\n' ||
		'ASIN: ' || ASIN || '<br>\n' ||
		'Price: ' || ListPriceAmt || '<br>\n' AS ProductDetail,
		DetailPageURL,
		COALESCE(MediumImageURL, 'http://www.visubuy.com/noimgavail.png') AS Image
	FROM Books
	WHERE PubDate > '1995-01-01'	-- an ANSI comment
		AND POWER_SEARCH('author: bunce', 'subject: perl*')
		AND Price < 100.00
	ORDER BY SalesRank DESC, AvgStars DESC
	LIMIT 100
	-- another ANSI comment");

print "not ok $testnum $testname failed:  ", $dbh->errstr, "\n"
	unless $sth;

exec_and_display($sth, $testname, $testnum)
	if $sth;
#
#	ItemSearch: Test 5:
#	test LIKE
#
$testnum++;
$testname = 'LIKE ItemSearch';
$sth = $dbh->prepare(
"SELECT PublicationDate AS PubDate,
		ListPriceAmt AS Price,
		SalesRank,
		AverageRating AS AvgStars,
		'Title: ' || Title || '<br>\n' ||
		'Author(s): ' || Authors || '<br>\n' ||
		'Publisher: ' || Publisher || '<br>\n' ||
		'ASIN: ' || ASIN || '<br>\n' ||
		'Price: ' || ListPriceAmt || '<br>\n' AS ProductDetail,
		DetailPageURL,
		COALESCE(MediumImageURL, 'http://www.visubuy.com/noimgavail.png') AS Image
	FROM Books
	WHERE PubDate > '1999-01-01'
		AND Subject LIKE 'Perl%'
		AND Price < 100.00
	ORDER BY SalesRank DESC, AvgStars DESC
	LIMIT 100");

print "not ok $testnum $testname failed:  ", $dbh->errstr, "\n"
	unless $sth;

exec_and_display($sth, $testname, $testnum)
	if $sth;
#
#	ItemSearch: Test 6:
#	test cached queries, IN evaluation,
#	REPLACE, and DECODE
#
$testnum++;
$testname = 'Cached ItemSearch';
$sth = $dbh->prepare(
"SELECT PublicationDate AS PubDate,
		ListPriceAmt AS Price,
		DECODE(ASIN,
			'1565926994',	'The Cheetah',
			'0596000278',	'The Camel',
			'0764537504',	'For Dummies',
			'0201419750',	'Effectively',
			'1884777791',	'OO perl',
			'Something else') as MappedAsin,
		SalesRank,
		AverageRating AS AvgStars,
		'Title: ' || Title || '<br>\n' ||
		'Author(s): ' || Authors || '<br>\n' ||
		'Publisher: ' || Publisher || '<br>\n' ||
		'ASIN: ' || ASIN || '<br>\n' ||
		'Price: ' || ListPriceAmt || '<br>\n' AS ProductDetail,
		REPLACE(DetailPageURL, 's/www\.amazon\.com/www.visubuy.com/g') AS URL,
		COALESCE(MediumImageURL, 'http://www.visubuy.com/noimgavail.png') AS Image
	FROM CachedBooks
	WHERE PubDate > '1999-01-01'
		AND Price < 100.00
		AND ASIN IN (
		'1565926994',	-- DBI
		'0596000278',	-- The Camel
		'0764537504',	-- for dummies
		'0201419750',	-- effectively
		'1884777791')	-- OO perl
	ORDER BY SalesRank DESC, AvgStars DESC
	LIMIT 100");

print "not ok $testnum $testname failed:  ", $dbh->errstr, "\n"
	unless $sth;

exec_and_display($sth, $testname, $testnum)
	if $sth;

$dbh->disconnect;

$loaded = 1;

sub exec_and_display {
	my ($sth, $testname, $testno) = @_;

	my $rc = $sth->execute;
	print "not ok $testno $testname failed: ", $sth->errstr, "\n" and
	return 1
		unless defined($rc);
	
	print "not ok $testno $testname failed: No rows returned\n" and
	return 1
		unless $rc;

	my $count = 0;
	
	$count++
		while ($row = $sth->fetchrow_arrayref);
	
	print "not ok $testno $testname failed: Rows reported != rows fetched\n" and
	return 1
		unless ($count == $rc);
	
	print "ok $testno $testname OK\n";
	return 1;
}
