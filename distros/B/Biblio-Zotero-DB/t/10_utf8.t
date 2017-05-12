use strict;
use warnings;
use Test::Most tests => 1;

use lib "t/lib";
use TestData;
use utf8::all;
use Unicode::Normalize;

my $db = get_db();

my $item = $db
  ->schema->resultset('Item')
  ->search_by_field( {
    title => { like => '%City%' }
  } )->first;

my $authors = [
  map { [ NFC($_->lastname), NFC($_->firstname) ] } # canonicalise all the strings
  map { $_->creatorid->creatordataid }
  $item->item_creators->all
];

cmp_deeply( $authors, bag(
  [ NFC("Salesses"),   NFC("Philip") ],
  [ NFC("Schechtner"), NFC("Katja") ],
  [ NFC("Hidalgo"),    NFC("César A.") ]
), 'match UTF-8 in author names');
