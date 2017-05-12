package TestApp::Controller::Root;

use TestApp::Object;
use base qw ( Catalyst::Controller );
use strict;
use warnings;

__PACKAGE__->config->{namespace} = "";

sub literal :Local {
  ( my $self, my $c ) = @_;

  my $data = [
    [ "1", "first entry" ],
    [ "2", "second" ],
    [ "3", "third" ],
    { index => "4", entry => "fourth" },
    TestApp::Object->new ( index => 5, entry => "fifth" ),
  ];
  $c->stash ( data => $data,
	      columns => [ qw ( index entry ) ],
	      current_view => "CSV" );
}

sub db :Local {
  ( my $self, my $c ) = @_;

  my $resultset = $c->model ( "TestDB::Person" )->search ( undef, {
    select => [ qw ( name age ) ],
    order_by => [ qw ( name age ) ],
  } );
  $c->stash ( cursor => $resultset->cursor,
	      columns => [ qw ( Name Age ) ],
	      current_view => "CSV" );
}

sub noheader :Local {
  ( my $self, my $c ) = @_;

  my $resultset = $c->model ( "TestDB::Person" )->search ( undef, {
    select => [ qw ( name age ) ],
    order_by => [ qw ( name age ) ],
  } );
  $c->stash ( cursor => $resultset->cursor,
	      current_view => "CSV" );
}

sub tsv :Local {
  ( my $self, my $c ) = @_;

  my $resultset = $c->model ( "TestDB::Person" )->search ( undef, {
    select => [ qw ( name age ) ],
    order_by => [ qw ( age name ) ],
  } );
  $c->stash ( cursor => $resultset->cursor,
	      columns => [ qw ( Name Age ) ],
	      current_view => "TSV" );
}

sub filename :Local {
  ( my $self, my $c ) = @_;

  my $resultset = $c->model ( "TestDB::Person" )->search ( undef, {
    select => [ qw ( name age ) ],
    order_by => [ qw ( age name ) ],
  } );
  $c->stash ( cursor => $resultset->cursor,
	      columns => [ qw ( Name Age ) ],
	      filename => "explicit.txt",
	      current_view => "CSV" );
}

sub end :ActionClass("RenderView") {
}

1;
