#!/usr/bin/perl
#
# Copyright (c) 2007 by the cairo perl team (see the file README)
#
# Licensed under the LGPL, see LICENSE file for more information.
#
# $Id$
#

use strict;
use warnings;

use Test::More;

use Cairo;

unless (Cairo::HAS_FT_FONT && eval 'use Font::FreeType; 1;') {
	plan skip_all => 'need Cairo with FreeType support and Font::FreeType';
}

my @files_to_try = qw(
  /usr/share/fonts/truetype/ttf-bitstream-vera/Vera.ttf
  /usr/share/fonts/truetype/ttf-dejavu/DejaVuSerif.ttf
);
my @files_found = grep { -r $_ } @files_to_try;
my $file = $files_found[0];
unless ($file) {
	plan skip_all => 'can\'t find font file';
}

plan tests => 3;

my $ft_face = Font::FreeType->new->face ($file);
my $cr_ft_face = Cairo::FtFontFace->create ($ft_face);
isa_ok ($cr_ft_face, 'Cairo::FtFontFace');
isa_ok ($cr_ft_face, 'Cairo::FontFace');
is ($cr_ft_face->status, 'success');


# make sure freetype font object is correctly referenced
{
  sub draw_text {
    my $cr = shift;

    my $ft_face = Font::FreeType->new->face( $file );
    my $face = Cairo::FtFontFace->create($ft_face);
    $cr->set_font_face( $face );
    $cr->set_font_size( 12 );
    $cr->translate( 10 , 10 );
    $cr->show_text( "123 123123" );
    $cr->stroke;
  }

  my $surface = Cairo::PdfSurface->create( "test.pdf", 500 , 500 );
  my $cr = Cairo::Context->create($surface);
  $cr->save;
  draw_text( $cr );
  $cr->set_font_size( 12 );
  $cr->restore;

  # must call finish() here so that cairo attemps to use the FtFontFace
  $surface->finish;

  unlink "test.pdf";
}
