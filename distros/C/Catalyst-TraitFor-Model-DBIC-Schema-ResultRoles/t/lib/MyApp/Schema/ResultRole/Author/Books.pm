package MyApp::Schema::ResultRole::Author::Books;

use Moose::Role;
requires qw/book_authors/;

MyApp::Schema::Result::Book->many_to_many(books => 'book_authors', 'book');

no Moose::Role;
1;
