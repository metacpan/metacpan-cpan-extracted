# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl functions.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN {
	use_ok('DBIx::MyParse');
	use_ok('DBIx::MyParse::Query');
	use_ok('DBIx::MyParse::Item')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = DBIx::MyParse->new();
$parser->setDatabase('database1');

ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

use Data::Dumper;

#
# CASE
#

my $case = $parser->parse("
	SELECT CASE 3 WHEN 1 THEN 'one' WHEN 2 THEN 'two' ELSE 'more' END;
");

my $soundex = $parser->parse("
	SELECT 'Microsoft' SOUNDS LIKE 'Linix'
");

my $trim = $parser->parse("
	SELECT TRIM(LEADING 'x' FROM 'xxxbarxxx')
");

my $like = $parser->parse("
	SELECT expr LIKE '%test_' ESCAPE '|'
");

my $regexp = $parser->parse("
	SELECT 'a' REGEXP BINARY 'A'
");

my $date_add = $parser->parse("
	SELECT DATE_ADD('1998-01-02', INTERVAL 31 DAY)
");

my $adddate = $parser->parse("
	SELECT ADDDATE('1998-01-02', INTERVAL 31 DAY)
");

my $interval = $parser->parse("
	SELECT '1997-12-31 23:59:59' + INTERVAL 1 SECOND
");

my $extract = $parser->parse("
	SELECT EXTRACT(YEAR_MONTH FROM '1999-07-02 01:02:03');
");

my $get_format = $parser->parse("
	SELECT GET_FORMAT(DATE,'INTERNAL')
");

#
# Mysql 5.0
#
# my $timestampadd = DBIx::MyParse->parse("
# 	SELECT TIMESTAMPADD(MINUTE,1,'2003-01-02')
# ");

my $fulltext1 = $parser->parse("
	SELECT * FROM articles WHERE MATCH (title,body) AGAINST ('database' IN BOOLEAN MODE)
");

my $fulltext2 = $parser->parse("
	SELECT * FROM articles WHERE MATCH (title,body) AGAINST ('database' WITH QUERY EXPANSION)
");

my $binary = $parser->parse("
	SELECT BINARY 'a' = 'A'
");

my $convert = $parser->parse("
	SELECT CONVERT('string' USING latin1)
");

my $cast = $parser->parse("
	SELECT CAST(expr AS SIGNED)
");

my $coercibility = $parser->parse("
	SELECT COERCIBILITY('abc' COLLATE latin1_swedish_ci);
");

#
# 
#

my $round = $parser->parse(" SELECT ROUND(1,2) ");


my $equal = $parser->parse(" SELECT a = 'b' ");
use Data::Dumper;
print Dumper $equal;
