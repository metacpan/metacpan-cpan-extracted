package MyApp::Schema::ResultRole::Book::Authors;

use Moose::Role;
requires qw/book_authors/;

MyApp::Schema::Result::Book->many_to_many(authors => 'book_authors', 'author');

no Moose::Role;
1;
