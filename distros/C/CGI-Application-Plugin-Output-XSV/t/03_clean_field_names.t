#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
  use_ok( 'CGI::Application::Plugin::Output::XSV', qw(:all) );
}

# clean field names
my $ref= [ qw(foo bar baz) ];
my $newref= clean_field_names( $ref );
isnt( $ref, $newref, "clean_field_names creates new list [$ref -> $newref]" );

foreach(
  [ [ qw(foo bar baz) ], [ qw(Foo Bar Baz) ] ],
  [ [ 'foo bar', 'baz qux' ], [ 'Foo Bar', 'Baz Qux' ] ],
)
{
  my $clean= clean_field_names( $_->[0] );
  is_deeply( $clean, $_->[1],
      qq(matching clean ["@{$_->[0]}" -> "@$clean"]) );
}

foreach(
  [ [ qw(foo bar baz) ], [ qw(foo bar baz) ] ],
  [ [ 'foo bar', 'baz qux' ], [ 'foo bar', 'baz qux' ] ],
)
{
  my $clean= clean_field_names( $_->[0] );
  isnt( "@$clean", "@{$_->[1]}",
        qq(unmatching clean ["@$clean" ne "@{$_->[1]}"]) );
}
