#!/usr/bin/perl
use v5.26;
use warnings;
use experimental qw(signatures);

use Test2::V0;

use Data::Transfigure::Type::DBIx;
use Data::Transfigure::Constants;

my $d = Data::Transfigure::Type::DBIx->new();

use FindBin qw($RealBin);
use lib "$RealBin/lib";
use MyApp::Schema;

my $schema = MyApp::Schema->connect('dbi:SQLite:dbname=:memory:', '', '');
my $author = $schema->resultset('Person')->new({firstname => 'Brandon', lastname => 'Sanderson'});
my $book   = $schema->resultset('Book')->new({title => 'The Final Empire', author => $author});

ok($d->applies_to(value => bless({}, 'MyClass')), $NO_MATCH,             'check dbix not applies_to (MyClass)');
ok($d->applies_to(value => $book),                $MATCH_INHERITED_TYPE, 'check dbix applies_to (book)');
ok($d->applies_to(value => $author),              $MATCH_INHERITED_TYPE, 'check dbix applies_to (person)');

ok($d->transfigure($book),   {id => 1, title     => 'The Final Empire', author_id => 1}, 'non-recursive dbix transfigure (book)');
ok($d->transfigure($author), {id => 1, firstname => 'Brandon', lastname => 'Sanderson'}, 'non-recursive dbix transfigure (person)');

done_testing;
