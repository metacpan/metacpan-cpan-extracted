#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use App::sdview::Style;

use Convert::Color;

# Default style
{
   is( App::sdview::Style->para_style( "head1" ),
      {
         bold => T(),
         fg   => Convert::Color->new( "vga:yellow" ),
      },
      'Default head1 paragraph style' );

   is( App::sdview::Style->inline_style( "monospace" ),
      {
         monospace => T(),
         bg        => Convert::Color->new( "xterm:235" ),
      },
      'Default monospace inline style' );

   is( App::sdview::Style->highlight_style( "string" ),
      {
         fg => Convert::Color->new( "vga:magenta" ),
      },
      'Default string highlight style' );

   is( App::sdview::Style->highlight_style( "method" ),
      {
         fg => Convert::Color->new( "xterm:147" ),
      },
      'Default method highlight style falls back to keyword' );
}

# Load a custom config file
{
   App::sdview::Style->load_config( \*DATA );

   is( App::sdview::Style->para_style( "head1" ),
      {
         bold => T(),
         fg   => Convert::Color->new( "vga:red" ),
      },
      'Overridden head1 paragraph style' );

   is( App::sdview::Style->inline_style( "monospace" ),
      {
         monospace => T(),
      },
      'Overridden monospace inline style' );

   is( App::sdview::Style->highlight_style( "comment" ),
      {
         italic => T(),
         fg     => Convert::Color->new( "vga:blue" ),
      },
      'Overridden comment highlight style' );
}

done_testing;

__DATA__
[Para head1]
fg = vga:red

[Inline monospace]
bg = ~

[Highlight comment]
fg = vga:blue
bg = ~
