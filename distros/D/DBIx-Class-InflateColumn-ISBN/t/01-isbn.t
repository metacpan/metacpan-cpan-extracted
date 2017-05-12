#!perl -T
use strict;
use warnings;

use lib qw(t/lib);
use DBICTest;
use Test::More tests => 23;
use Business::ISBN;

my $schema = DBICTest->init_schema();
my $rs     = $schema->resultset('Library');

my $code = '0321430840';

my $book = $rs->find(1);
isa_ok($book->isbn, 'Business::ISBN', 'data inflated to right class');
is($book->isbn->isbn, $code, 'data correctly inflated');
isa_ok($book->full_isbn, 'Business::ISBN', 'full_isbn data inflated to right class');
is($book->full_isbn->isbn, $code, 'full_isbn data correctly inflated');

$book = $rs->find(2);
isa_ok($book->isbn, 'Business::ISBN', 'data inflated to right class');
isa_ok(\$book->book, 'SCALAR', 'other field not inflated');
is($book->isbn->isbn, '190351133X', 'data with X correctly inflated');

my $book2;
TODO: {
    local $TODO = "DBIx::Class doesn't support find by object yet";
    $book2 = $rs->find( Business::ISBN->new($code),
                          { key => 'isbn' } );
    ok($book2, 'find by object returned a row');
}
SKIP: {
    skip 'no find object to check' => 1 unless $book2;
    is($book2->isbn->isbn, $code, 'find by object returned the right row');
}

my $book1 = $rs->search( isbn => Business::ISBN->new($code) );
ok($book1, 'search by object returned a row');
$book1 = $book1->first;
SKIP: {
    skip 'no search object to check' => 1 unless $book1;
    is($book1->isbn, $code, 'search by object returned the right row');
}

my $isbn = Business::ISBN->new('0374292795');
$book = $rs->create({ book => 'foo', isbn => $isbn });
isa_ok($book, 'DBICTest::Library', 'create with object (1)');
is($book->get_column('isbn'), $isbn->isbn, 'numeric code correctly deflated');

$isbn = Business::ISBN->new('0575073772');
$book = $rs->create({ book => 'The Last Hero', isbn => $isbn, full_isbn => $isbn });
isa_ok($book, 'DBICTest::Library', 'create with object (2)');
is($book->get_column('full_isbn'), $isbn->as_string, 'as_string code correctly deflated');

$isbn = Business::ISBN->new('071351700X');
$book = $rs->create({ book => 'Elementary Mechanics', isbn => $isbn });
isa_ok($book, 'DBICTest::Library', 'create with object (3)');
is($book->get_column('isbn'), $isbn->isbn, 'code with X correctly deflated');
ok($book->isbn->is_valid, 'validation checked');

$isbn = Business::ISBN->new('0713517001');
my $host = $rs->create({ book => 'Elementary Mechanics', isbn => $isbn });
isa_ok($host, 'DBICTest::Library', 'create with object (4)');
is($host->get_column('isbn'), $isbn->isbn, 'invalid code correctly deflated');
isnt($host->isbn->is_valid_checksum, Business::ISBN::GOOD_ISBN, 'validation error checked');

#$isbn = Business::ISBN->new('foobar');
#eval { $book = $rs->create({ book => 'foobar', isbn => $isbn }); };
#ok($@, 'check for error with invalid data');

$isbn = Business::ISBN->new('978-0-596-52724-2');
SKIP: {
    skip 'ISBN13 not supported' => 2 unless $isbn;
    my $host = $rs->create({ book => 'baz', isbn => $isbn->isbn });
    isa_ok($host, 'DBICTest::Library', 'create with object');
    is($host->get_column('isbn'), $isbn->isbn, 'numeric code correctly deflated');
}
