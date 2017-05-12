package TestApp::Controller::Single;

use strict;
use warnings;
use base qw( Catalyst::Controller );

sub setup : Local {
  my ( $self, $c ) = @_;

  $c->forward('cleanup', 1);  # remove previous database if any

  $c->model('JDBI')->setup_database;

  # insert default data
  $c->model('JDBI::Book')->create(
    name => 'Perl Best Practices',
    isbn => '0-596-00173-8',
  );
  $c->model('JDBI::Book')->create(
    name => 'Perl Hacks',
    isbn => '0-596-52674-1',
  );

  $c->model('JDBI::Author')->create(
    name    => 'Damian Conway',
    pauseid => 'DCONWAY',
  );
  $c->model('JDBI::Author')->create(
    name    => 'chromatic',
    pauseid => 'CHROMATIC',
  );

  $c->response->body( 1 );
}

sub cleanup : Local {
  my ( $self, $c, $no_return ) = @_;

  my $testdb = $c->model('JDBI')->database;

  return unless $testdb && -e $testdb;

  # to avoid Permission issue on some platforms
  $c->model('JDBI')->disconnect;

  unlink $testdb or die "Can't remove previous database: $!";

  unless ( $no_return ) {
    $c->response->body( 1 );
  }
}

sub book : Local {
  my ( $self, $c ) = @_;

  my $book = $c->model('JDBI::Book');
     $book->load(1);
  if ( $book->id ) {
    $c->response->body( $book->id );
  }
  else {
    $c->response->body( 0 );
  }
}

sub book_collection : Local {
  my ( $self, $c ) = @_;

  my $books = $c->model('JDBI::BookCollection');
     $books->unlimit;
  if ( $books->first ) {
    $c->response->body( $books->first->name );
  }
  else {
    $c->response->body( 0 );
  }
}

sub author : Local {
  my ( $self, $c ) = @_;

  my $author = $c->model('JDBI::Author');
     $author->load(1);
  if ( $author->id ) {
    $c->response->body( $author->pauseid );
  }
  else {
    $c->response->body( 0 );
  }
}

sub author_collection : Local {
  my ( $self, $c ) = @_;

  # This collection is provided automatically by C::M::Jifty::DBI!
  my $authors = $c->model('JDBI::AuthorCollection');
     $authors->unlimit;
  if ( $authors->first ) {
    $c->response->body( $authors->first->name );
  }
  else {
    $c->response->body( 0 );
  }
}

sub book_false : Local {
  my ( $self, $c ) = @_;

  my $book = $c->model('JDBI::Book');
     $book->load_by_cols( name => 'my book');
  if ( $book->id ) {
    $c->response->body( 0 );  # shouldn't be found
  }
  else {
    $c->response->body( 1 );
  }
}

sub book_collection_false : Local {
  my ( $self, $c ) = @_;

  my $books = $c->model('JDBI::BookCollection');
     $books->limit( column => 'name', value => 'my book' );
  if ( $books->first ) {
    $c->response->body( 0 ); # shouldn't be found
  }
  else {
    $c->response->body( 1 );
  }
}

sub author_false : Local {
  my ( $self, $c ) = @_;

  my $author = $c->model('JDBI::Author');
     $author->load_by_cols( name => 'nowhere man' );
  if ( $author->id ) {
    $c->response->body( 0 ); # shouldn't be found
  }
  else {
    $c->response->body( 1 );
  }
}

sub author_collection_false : Local {
  my ( $self, $c ) = @_;

  # This collection is provided automatically by C::M::Jifty::DBI!
  my $authors = $c->model('JDBI::AuthorCollection');
     $authors->limit( column => 'pauseid', value => 'FOOBAR' );
  if ( $authors->first ) {
    $c->response->body( 0 ); # shouldn't be found
  }
  else {
    $c->response->body( 1 );
  }
}

1;
