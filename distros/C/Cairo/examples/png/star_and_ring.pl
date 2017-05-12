#!/usr/bin/env perl

# This a Perl port of the C example cairo-demo/png/star_and_ring.c.  Original
# copyright:

# Copyright © 2005 Red Hat, Inc.
#
# Permission to use, copy, modify, distribute, and sell this software
# and its documentation for any purpose is hereby granted without
# fee, provided that the above copyright notice appear in all copies
# and that both that copyright notice and this permission notice
# appear in supporting documentation, and that the name of
# Red Hat, Inc. not be used in advertising or publicity pertaining to
# distribution of the software without specific, written prior
# permission. Red Hat, Inc. makes no representations about the
# suitability of this software for any purpose.  It is provided "as
# is" without express or implied warranty.
#
# RED HAT, INC. DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
# SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS, IN NO EVENT SHALL RED HAT, INC. BE LIABLE FOR ANY SPECIAL,
# INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
# RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
# OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Author: Carl D. Worth <cworth@cworth.org>

use strict;
use warnings;
use Cairo;

use constant {
  WIDTH => 600,
  HEIGHT => 600,
};

sub ring_path {
  my ($cr) = @_;

  $cr->move_to (200.86568, 667.80795);
  $cr->curve_to (110.32266, 562.62134,
                 122.22863, 403.77940,
                 227.41524, 313.23637);
  $cr->curve_to (332.60185, 222.69334,
                 491.42341, 234.57563,
                 581.96644, 339.76224);
  $cr->curve_to (672.50948, 444.94884,
                 660.64756, 603.79410,
                 555.46095, 694.33712);
  $cr->curve_to (450.27436, 784.88016,
                 291.40871, 772.99456,
                 200.86568, 667.80795);
  $cr->close_path;

  $cr->move_to (272.14411, 365.19927);
  $cr->curve_to (195.64476, 431.04875,
                 186.97911, 546.57972,
                 252.82859, 623.07908);
  $cr->curve_to (318.67807, 699.57844,
                 434.23272, 708.22370,
                 510.73208, 642.37422);
  $cr->curve_to (587.23144, 576.52474,
                 595.85301, 460.99047,
                 530.00354, 384.49112);
  $cr->curve_to (464.15406, 307.99176,
                 348.64347, 299.34979,
                 272.14411, 365.19927);
  $cr->close_path;
}

sub star_path {
  my ($cr) = @_;

  my $matrix = Cairo::Matrix->init (0.647919, -0.761710,
                                    0.761710, 0.647919,
                                    -208.7977, 462.0608);
  $cr->transform ($matrix);

  $cr->move_to (505.80857, 746.23606);
  $cr->line_to (335.06870, 555.86488);
  $cr->line_to (91.840384, 635.31360);
  $cr->line_to (282.21157, 464.57374);
  $cr->line_to (202.76285, 221.34542);
  $cr->line_to (373.50271, 411.71660);
  $cr->line_to (616.73103, 332.26788);
  $cr->line_to (426.35984, 503.00775);
  $cr->line_to (505.80857, 746.23606);
  $cr->close_path;
}

sub fill_ring {
  my ($cr) = @_;

  $cr->save;
  $cr->translate (-90, -205);
  ring_path ($cr);
  $cr->set_source_rgba (1.0, 0.0, 0.0, 0.75);
  $cr->fill;
  $cr->restore;
}

sub fill_star {
  my ($cr) = @_;

  $cr->save;
  $cr->translate (-90, -205);
  star_path ($cr);
  $cr->set_source_rgba (0.0, 0.0, 0xae / 0xff, 0.55135137);
  $cr->fill;
  $cr->restore;
}

sub clip_to_top_and_bottom {
  my ($cr, $width, $height) = @_;
  $cr->move_to (0, 0);
  $cr->line_to ($width, 0);
  $cr->line_to (0, $height);
  $cr->line_to ($width, $height);
  $cr->close_path;
  $cr->clip;
  $cr->new_path;
}

sub clip_to_left_and_right {
  my ($cr, $width, $height) = @_;
  $cr->move_to (0, 0);
  $cr->line_to (0, $height);
  $cr->line_to ($width, 0);
  $cr->line_to ($width, $height);
  $cr->close_path;
  $cr->clip;
  $cr->new_path;
}

{
  my $result = Cairo::ImageSurface->create ('argb32', WIDTH, HEIGHT);
  my $ring_over_star = Cairo::ImageSurface->create ('argb32', WIDTH, HEIGHT);
  my $star_over_ring = Cairo::ImageSurface->create ('argb32', WIDTH, HEIGHT);

  my $cr = Cairo::Context->create ($result);

  {
    my $cr_ros = Cairo::Context->create ($ring_over_star);
    clip_to_top_and_bottom ($cr_ros, WIDTH, HEIGHT);
    fill_star ($cr_ros);
    fill_ring ($cr_ros);
  }

  {
    my $cr_sor = Cairo::Context->create ($star_over_ring);
    clip_to_left_and_right ($cr_sor, WIDTH, HEIGHT);
    fill_ring ($cr_sor);
    fill_star ($cr_sor);
  }

  $cr->set_operator ('add');
  $cr->set_source_surface ($ring_over_star, 0, 0);
  $cr->paint;
  $cr->set_source_surface ($star_over_ring, 0, 0);
  $cr->paint;

  $result->write_to_png ("star_and_ring.png");
}
