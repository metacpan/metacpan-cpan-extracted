#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Transfigure;

my $t = Data::Transfigure->bare();
$t->add_transfigurators(qw(Data::Transfigure::HashKeys::CamelCase));

my $h = {id => 1};

is($t->transfigure($h), {id => 1}, 'id key');

$h = {ID => 1};

is($t->transfigure($h), {id => 1}, 'ID key');

$h = {book_id => 1};

is($t->transfigure($h), {bookId => 1}, '...Id key');

$h = [
  {id => {table_id => 3}},
  {
    list => [
      qw(
        book_id
        id
        table_id
        ID),
      {my_id => 3}
    ]
  }
];

is($t->transfigure($h), [{id => {tableId => 3}}, {list => ['book_id', 'id', 'table_id', 'ID', {myId => 3}]}], 'deep key rewrite');

done_testing;
