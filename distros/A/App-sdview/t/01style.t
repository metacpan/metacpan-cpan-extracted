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
}

done_testing;

__DATA__
[Para head1]
fg = vga:red
