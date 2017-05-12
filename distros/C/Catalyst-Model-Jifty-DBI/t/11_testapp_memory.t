use strict;
use warnings;
use Test::More;
use lib qw( t/TestApp/lib );

local $ENV{CM_JDBI_MEMORY} = 1;

use Catalyst::Test qw( TestApp );

my @tests_1 = (
  'setup' => 1, 

  # positive tests
  'book'              => 1,
  'book_collection'   => 'Perl Best Practices',

  'author'            => 'DCONWAY',
  'author_collection' => 'Damian Conway',

  # negative tests
  'book_false'              => 1,
  'book_collection_false'   => 1,

  'author_false'            => 1,
  'author_collection_false' => 1,

  'cleanup' => 1,
);

my @tests_2 = (
  'setup' => 1, 

  # default positive tests
  'book'              => 1,
  'book_collection'   => 'Perl Best Practices',

  'author'            => 'DCONWAY',
  'author_collection' => 'Damian Conway',

  # default negative tests
  'book_false'              => 1,
  'book_collection_false'   => 1,

  'author_false'            => 1,
  'author_collection_false' => 1,

  # db1 positive tests
  'book_db1'              => 1,
  'book_collection_db1'   => 'Perl Best Practices',

  'author_db1'            => 'DCONWAY',
  'author_collection_db1' => 'Damian Conway',

  # db1 negative tests
  'book_false_db1'              => 1,
  'book_collection_false_db1'   => 1,

  'author_false_db1'            => 1,
  'author_collection_false_db1' => 1,

  # db2 positive tests
  'book_db2'              => 1,
  'book_collection_db2'   => 'Catalyst',

  'author_db2'            => 'JROCKWAY',
  'author_collection_db2' => 'Jonathan Rockway',

  # db2 negative tests
  'book_false_db2'              => 1,
  'book_collection_false_db2'   => 1,

  'author_false_db2'            => 1,
  'author_collection_false_db2' => 1,

  'cleanup' => 1,
);

plan tests => (( scalar @tests_1 + scalar @tests_2 ) / 2 );

while( my ($path, $result) = splice @tests_1, 0, 2 ) {
  is get("/single/$path"), $result;
}

while( my ($path, $result) = splice @tests_2, 0, 2 ) {
  is get("/multi/$path"), $result;
}

