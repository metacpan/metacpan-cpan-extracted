#
# biblio @ pc-nerz
#
use strict;
# use Test::More tests => 1;
use Test::More skip_all => "Cannot assume that there is a ODBC data source available";

use DBI;

#  my $db = DBI->connect("dbi:ODBC:biblio", "biblio", "biblio", {})
      #  or die "$DBI::errstr\nCannot connect";
my $db = DBI->connect("dbi:mysqlPP:database=biblio;host=pc-nerz", "biblio", "biblio", {})
      or die "$DBI::errstr\nCannot connect";

  my $sth = $db->prepare("select * from biblio")
      or die "$DBI::errstr\nCannot prepare SQL stmt\n";
  $sth->execute(@params)
      or die "$DBI::errstr\nCannot execute SQL statement";

my @row;
  while ( @row = $sth->fetchrow_array() ) {
    print "@row\n";
  }



$db->do(<<SQL
INSERT INTO biblio (
    CiteKey,
    CiteType,
    Category,
    Title,
    Journal,
    Authors,
    Volume,
    Number,
    Pages
    ) VALUES (
    'test-key',
    0,
    'test',
    'title',
    'journal',
    'author1, author2',
    '1',
    '2',
    '3--4'
    )
SQL
	) or die "$DBI::errstr\nCannot execute SQL statement";

$db->disconnect();
