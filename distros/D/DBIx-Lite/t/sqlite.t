#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 20;
use DBIx::Lite;

my $dbix = DBIx::Lite->new;
$dbix->connect('dbi:SQLite:dbname=t/test.db', '', '');

$dbix->dbh->do('DROP TABLE IF EXISTS books');
$dbix->dbh->do('DROP TABLE IF EXISTS authors');
$dbix->dbh->do('CREATE TABLE authors (id NUMBER, name TEXT, age NUMBER)');
$dbix->table('authors')->insert({ id => 1, name => 'Larry Wall', age => 30 });
$dbix->table('authors')->insert({ id => 2, name => 'John Smith', age => 50 });
$dbix->dbh->do('CREATE TABLE books (id NUMBER, title TEXT, year NUMBER, author_id NUMBER)');
$dbix->table('books')->insert({ id => 1, title => 'Camel Tales', year => 2012, author_id => 1 });
$dbix->table('books')->insert({ id => 2, title => 'Camel Adventures', year => 2010, author_id => 1 });
$dbix->schema->table('authors')->pk('id');
$dbix->schema->table('books')->pk('id');

{
    my $count = $dbix->table('books')->count;
    is $count, 2, 'row count';
}

{
    my $book = $dbix->table('books')->find({ year => 2010 });
    isa_ok $book, 'DBIx::Lite::Row';
    is $book->id, 2, 'fetch result';
}

{
    my $rows = $dbix->table('books')->search({ year => 2010 })->update({ year => 2011 });
    pass 'update';
    is $rows, 1, 'rows affected by update';
}

{
    my @titles = $dbix->table('books')->order_by('+title')->get_column('title');
    is_deeply \@titles, ['Camel Adventures', 'Camel Tales'], 'get_column';
}

foreach my $table_alias ('', 'me.', 'authors.') {
    my $rs = $dbix->table('authors')
        ->left_join('books', { "${table_alias}id" => 'author_id' })
        ->search({ "me.name" => 'Larry Wall' });
    is $rs->count, 2, "join with '$table_alias' prefix";
}

{
    my $rs = $dbix->table('books')
        ->inner_join('authors', { 'author_id' => 'id', 'authors.age' => { '<' => 35 } });
    is $rs->count, 2, "join with hashref condition";
}

{
    my @expect = qw( id title year author_id );

    my $column_names_ref = $dbix->table('books')->column_names;
    is_deeply $column_names_ref, \@expect, 'column_names in scalar context';

    my @column_names = $dbix->table('books')->column_names;
    is_deeply \@column_names, \@expect, 'column_names in list context';
}

{
    my $rs = $dbix->table('books')->search({ year => 2011 })->select('title');
    my ($sql, @bind) = $rs->select_sql;
    unlike $sql, qr/\bid\b/, 'no primary key is included in the select_sql() output';
    my $book = $rs->single;
    is $book->id, 2, 'primary key is populated when retrieving the object';
}

$dbix->schema->one_to_many('authors.id' => 'books.author_id', 'author');

{
    my $book = $dbix->table('books')->find({ id => 1 });
    my $author = $book->author;
    isa_ok $author, 'DBIx::Lite::Row';
    is $author->name, 'Larry Wall';
    is $author->books->count, 2;
}

$dbix->schema->one_to_many('authors.id' => 'books.author_id', ['published_books' => 'author']);

{
    my $book = $dbix->table('books')->find({ id => 1 });
    my $author = $book->author;
    isa_ok $author, 'DBIx::Lite::Row';
    is $author->name, 'Larry Wall';
    my $books = $author->published_books;
    is $books->count, 2;
}

__END__
