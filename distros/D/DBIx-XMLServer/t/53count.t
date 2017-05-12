use Test::More tests => 21;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 20
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t53.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, 'name=*', 't/o53-1.xml',
	rowcount => COUNT);
  try_query($xml_server, 'name=*&pagesize=2', 't/o53-2.xml',
	rowcount => COUNT);

  SKIP: {

    $dbh->do('SELECT SQL_CALC_FOUND_ROWS id FROM dbixtest1')
      or skip "Database doesn't support FOUND_ROWS", 8;

    try_query($xml_server, 'name=*', 't/o53-3.xml',
	      rowcount => FOUND_ROWS);
    try_query($xml_server, 'name=*&pagesize=2', 't/o53-4.xml',
	      rowcount => FOUND_ROWS);
  }
   
  close_db();

}

1;
