#!/usr/bin/perl -w

use strict;
use warnings;

package My::Book;
use Moo;

has '_row' => (is => 'ro', default => sub { {} });

use Test::More tests => 2;
use DBIx::Lite;

my $dbix = DBIx::Lite->new;
$dbix->connect('dbi:SQLite:dbname=t/test.db', '', '');

$dbix->dbh->do('DROP TABLE IF EXISTS books');
$dbix->dbh->do('CREATE TABLE books (id NUMBER, title TEXT, year NUMBER, author_id NUMBER)');
$dbix->table('books')->insert({ id => 1, title => 'Camel Tales', year => 2012, author_id => 1 });
$dbix->schema->table('books')->pk('id');
$dbix->schema->table('books')->class('My::Book', 'new', '_row');

{
    my $book = $dbix->table('books')->find({ id => 1 });
    isa_ok $book, 'My::Book';
    is $book->title, 'Camel Tales';
}

__END__
