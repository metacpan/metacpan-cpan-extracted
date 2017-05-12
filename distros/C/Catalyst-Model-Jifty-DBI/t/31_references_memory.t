use strict;
use warnings;
use Test::More 'no_plan';
use lib qw( t/TestReference/lib );

local $ENV{CM_JDBI_MEMORY} = 1;

use TestReference::Model::JDBI;

my $model = TestReference::Model::JDBI->new;

my $database = $model->database;
if ( $database && -f $database ) {
  $model->disconnect;
  unlink $database;
}

eval { $model->setup_database };
ok !$@, 'setup database successfully';
exit if $@;

$model->trace(0);

{ # prepare data
  my $author = $model->record('Author');
  my $author_id = $author->create( name => 'me' );

  my $book1 = $model->record('Book');
     $book1->create( name => 'A book', author => $author_id );
  my $book2 = $model->record('Book');
     $book2->create( name => 'Another book', author => $author_id );
}

{ # now test them
  my $author = $model->record('Author');
     $author->load_by_cols( name => 'me' );
  ok $author->id;

  my $books = $author->books;
     $books->unlimit;
  ok $books->isa('Jifty::DBI::Collection');
  ok $books->count == 2;
  ok $books->first->name eq 'A book';
}

{
  my $book = $model->record('Book');
     $book->load_by_cols( name => 'A book' );
  ok $book->id;

  my $author = $book->author;
  ok $author->isa('Jifty::DBI::Record');
  ok $author->name eq 'me';
}

END { # cleanup
  $model->disconnect;
  unlink $database if $database && -f $database;
}
