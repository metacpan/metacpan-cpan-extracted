#!perl

use strict;
use warnings;

use APR::HTTP::Headers::Compat;
use APR::Pool;
use APR::Table;
use Test::More tests => 10;

my $Pool = APR::Pool->new;

{
  my $table = APR::Table::make( $Pool, 1 );
  ok my $h = APR::HTTP::Headers::Compat->new( $table ), 'new';
  $h->header( 'Content-Type', 'text/plain' );
  is_deeply [ tcont( $table ) ], [ 'Content-Type', 'text/plain' ],
   'add';
  $h->push_header( 'Foo' => 1 );
  is_deeply [ tcont( $table ) ],
   [
    'Content-Type' => 'text/plain',
    'Foo'          => 1,
   ],
   'push 1';
  $h->push_header( 'Foo' => 2 );
  is_deeply [ tcont( $table ) ],
   [
    'Content-Type' => 'text/plain',
    'Foo'          => 1,
    'Foo'          => 2,
   ],
   'push 2';
  $h->remove_header( 'Content-Type' );
  is_deeply [ tcont( $table ) ],
   [
    'Foo' => 1,
    'Foo' => 2,
   ],
   'remove';
}

{
  my $table = APR::Table::make( $Pool, 1 );
  ok my $h = APR::HTTP::Headers::Compat->new( $table, Foo => 'bar' ),
   'new';
  is_deeply [ tcont( $table ) ], [ Foo => 'bar' ], 'init';
}

{
  my $table = APR::Table::make( $Pool, 1 );
  ok my $h = APR::HTTP::Headers::Compat->new( $table ), 'new';
  $table->set( Foo => 'bar' );
  is $h->header( 'Foo' ), 'bar', 'alter table';
  $table->add( Foo => 'baz' );
  is_deeply [ $h->header( 'Foo' ) ], [ 'bar', 'baz' ],
   'alter table again';
}

sub tcont {
  my $table = shift;
  my @cont  = ();
  $table->do(
    sub {
      my ( $k, $v ) = @_;
      push @cont, $k, $v;
    } );
  return @cont;
}

# vim:ts=2:sw=2:et:ft=perl

