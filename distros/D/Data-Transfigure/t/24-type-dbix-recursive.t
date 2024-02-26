#!/usr/bin/perl
use v5.26;
use warnings;
use experimental qw(signatures);

use Test2::V0;

use Data::Transfigure::Type::DBIx::Recursive;
use Data::Transfigure::Constants;

my $d = Data::Transfigure::Type::DBIx::Recursive->new();

use FindBin qw($RealBin);
use lib "$RealBin/lib";
use MyApp::Schema;

my $schema = MyApp::Schema->connect('dbi:SQLite:dbname=:memory:', '', '');
my $author = $schema->resultset('Person')->new({firstname => 'Brandon', lastname => 'Sanderson'});
my $book   = $schema->resultset('Book')->new({title => 'The Final Empire', author => $author});

ok($d->applies_to(value => $author), $MATCH_INHERITED_TYPE, 'check dbix-recursive applies_to (person)');
ok($d->applies_to(value => $book),   $MATCH_INHERITED_TYPE, 'check dbix-recursive applies_to (book)');

ok($d->transfigure($author), {id => 1, firstname => 'Brandon', lastname => 'Sanderson'}, 'dbix-recursive transfigure (person)');
ok(
  $d->transfigure($book),
  {id => 1, title => 'The Final Empire', author => {id => 1, firstname => 'Brandon'}},
  'dbix-recursive transfigure (book)'
);

done_testing;
