#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Transfigure;

my $t = Data::Transfigure->bare();
$t->add_transfigurators(qw(Data::Transfigure::HashKeys::CapitalizedIDSuffix));

my $h = {id => 1};

is($t->transfigure($h), {id => 1}, 'id key');

$h = {ID => 1};

is($t->transfigure($h), {ID => 1}, 'ID key');

$h = {bookId => 1};

is($t->transfigure($h), {bookID => 1}, '...Id key');

$h = [
  {id => {tableId => 3}},
  {
    list => [
      qw(
        bookId
        id
        tableId
        ID),
      {myId => 3}
    ]
  }
];

is($t->transfigure($h), [{id => {tableID => 3}}, {list => ['bookId', 'id', 'tableId', 'ID', {myID => 3}]}], 'deep key rewrite');

done_testing;
