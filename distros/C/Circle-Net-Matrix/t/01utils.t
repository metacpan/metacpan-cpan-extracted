#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Circle::Net::Matrix::Utils qw( parse_markdownlike );

{
   my $str = parse_markdownlike( "hello world" );
   ok( !ref $str, 'No markup yields plain string' );
}

# one tag
{
   my $str = parse_markdownlike( "an *italic* word" );
   ok( ref $str, 'Italic markup yields tagged string' );

   is( "$str", "an italic word", 'tagged string content' );
   my $e = $str->get_tag_extent( 5, "italic" );
   ok( $e, 'string has italic tag at 5' ) and do {
      is( $e->start, 3, 'italic starts at 3' );
      is( $e->length, 6, 'italic length is 6' );
   };
}

# bold and italic coexist
{
   my $str = parse_markdownlike( "**bold** and *italic*" );
   is( "$str", "bold and italic", 'tagged string content for mixed tags' );

   my @tags;
   $str->iter_extents( sub {
      my ( $e, $tag ) = @_;
      push @tags, [ $tag => $e->start, $e->length ];
   });

   is_deeply( \@tags,
      [ [ bold   => 0, 4 ],
        [ italic => 9, 6 ] ],
      'tag extents for mixed tags' );
}

# non-tags
{
   my $str = parse_markdownlike( "What is 6 * 9?" );
   ok( !ref $str, 'Non-tag is not confused' );
}

done_testing;
