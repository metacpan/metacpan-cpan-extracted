#!perl -w

use strict;
use Test::More tests => 4;

use APR::Pool;
use APR::Table;
use APR::HTTP::Headers::Compat;
use HTTP::Headers::ETag;

my $Pool = APR::Pool->new;

sub mk(@) {
  my $table = APR::Table::make( $Pool, 10 );
  return APR::HTTP::Headers::Compat->new( $table, @_ );
}

my $h = mk;

$h->etag( "tag1" );
is( $h->etag, qq("tag1") );

$h->etag( "w/tag2" );
is( $h->etag, qq(W/"tag2") );

$h->if_match( qq(W/"foo", bar, baz), "bar" );
$h->if_none_match( 333 );

$h->if_range( "tag3" );
is( $h->if_range, qq("tag3") );

my $t = time;
$h->if_range( $t );
is( $h->if_range, $t );

print $h->as_string;

