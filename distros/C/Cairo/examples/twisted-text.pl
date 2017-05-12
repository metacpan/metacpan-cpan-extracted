#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Pango;

# This is a port of pango's cairotwisted example written by Behdad Esfahbod.

sub two_points_distance {
  my ($a, $b) = @_;

  my $dx = $b->[0] - $a->[0];
  my $dy = $b->[1] - $a->[1];

  return sqrt($dx * $dx + $dy * $dy);
}

sub parametrize_path {
  my ($path) = @_;

  my $current_point;
  my @parametrization = ();

  foreach (0 .. $#{$path}) {
    my $data = $path->[$_];
    $parametrization[$_] = 0.0;

    if ($data->{type} eq "move-to") {
      $current_point = $data->{points}[0];
    }

    elsif ($data->{type} eq "line-to") {
      $parametrization[$_] = two_points_distance ($current_point, $data->{points}[0]);
      $current_point = $data->{points}[0];
    }

    elsif ($data->{type} eq "curve-to") {
      $parametrization[$_] = two_points_distance ($current_point, $data->{points}->[0]);
      $parametrization[$_] += two_points_distance ($data->{points}[0], $data->{points}[1]);
      $parametrization[$_] += two_points_distance ($data->{points}[1], $data->{points}[2]);
      $current_point = $data->{points}[2];
    }
  }

  return \@parametrization;
}

sub _fancy_cairo_stroke {
  my ($cr, $preserve) = @_;

  my $line_width = $cr->get_line_width;
  my $path = $cr->copy_path;
  $cr->new_path;

  $cr->save;
  $cr->set_line_width($line_width / 3);
  $cr->set_dash(0, 10, 10);
  foreach my $data (@{$path}) {
    my @points = @{$data->{points}};

    if ($data->{type} eq "move-to" ||
        $data->{type} eq "line-to")
    {
      $cr->move_to ($points[0][0], $points[0][1]);
    }

    elsif ($data->{type} eq "curve-to") {
      $cr->line_to ($points[0][0], $points[0][1]);
      $cr->move_to ($points[1][0], $points[1][1]);
      $cr->line_to ($points[2][0], $points[2][1]);
    }
  }
  $cr->stroke;
  $cr->restore;

  $cr->save;
  $cr->set_line_width ($line_width * 4);
  $cr->set_line_cap ("round");
  foreach my $data (@{$path}) {
    my @points = @{$data->{points}};

    if ($data->{type} eq "move-to") {
      $cr->move_to ($points[0][0], $points[0][1]);
    }

    elsif ($data->{type} eq "line-to") {
      $cr->rel_line_to (0, 0);
      $cr->move_to ($points[0][0], $points[0][1]);
    }

    elsif ($data->{type} eq "curve-to") {
      $cr->rel_line_to (0, 0);
      $cr->move_to ($points[0][0], $points[0][1]);
      $cr->rel_line_to (0, 0);
      $cr->move_to ($points[1][0], $points[1][1]);
      $cr->rel_line_to (0, 0);
      $cr->move_to ($points[2][0], $points[2][1]);
    }

    elsif ($data->{type} eq "close-path") {
      $cr->rel_line_to (0, 0);
    }
  }
  $cr->rel_line_to (0, 0);
  $cr->stroke;
  $cr->restore;

  foreach my $data (@{$path}) {
    my @points = @{$data->{points}};

    if ($data->{type} eq "move-to") {
      $cr->move_to ($points[0][0], $points[0][1]);
    }

    elsif ($data->{type} eq "line-to") {
      $cr->line_to ($points[0][0], $points[0][1]);
    }

    elsif ($data->{type} eq "curve-to") {
      $cr->curve_to ($points[0][0], $points[0][1],
                     $points[1][0], $points[1][1],
                     $points[2][0], $points[2][1]);
    }

    elsif ($data->{type} eq "close-path") {
      $cr->close_path;
    }
  }
  $cr->stroke;

  if ($preserve) {
    $cr->append_path ($path);
  }
}

sub fancy_cairo_stroke {
  my ($cr) = @_;
  _fancy_cairo_stroke ($cr, FALSE);
}

sub fancy_cairo_stroke_preserve {
  my ($cr) = @_;
  _fancy_cairo_stroke ($cr, TRUE);
}

sub transform_path {
  my ($path, $f, $closure) = @_;

  foreach my $data (@{$path}) {
    if ($data->{type} eq "curve-to") {
      $f->($closure, $data->{points}[2]);
      $f->($closure, $data->{points}[1]);
      $f->($closure, $data->{points}[0]);
    }

    elsif ($data->{type} eq "move-to" ||
           $data->{type} eq "line-to")
    {
      $f->($closure, $data->{points}[0]);
    }
  }
}

sub point_on_path {
  my ($param, $point) = @_;

  my $oldy = $point->[1];
  my $d = $point->[0];
  my $path = $param->{path};
  my $parametrization = $param->{parametrization};
  my ($ratio, $dx, $dy);

  my $data;
  my $current_point = undef;

  my $length = $#{$path};
  my $i;
  for ($i = 0; $i < $length && $d > $parametrization->[$i]; $i++) {
    $d -= $parametrization->[$i];
    $data = $path->[$i];

    if ($data->{type} eq "move-to" ||
        $data->{type} eq "line-to")
    {
      $current_point = $data->{points}[0];
    }

    elsif ($data->{type} eq "curve-to") {
      $current_point = $data->{points}[2];
    }
  }
  $data = $path->[$i];

  if ($data->{type} eq "line-to") {
    my $ratio = $d / $parametrization->[$i];
    $point->[0] = $current_point->[0] * (1 - $ratio) + $data->{points}[0][0] * $ratio;
    $point->[1] = $current_point->[1] * (1 - $ratio) + $data->{points}[0][1] * $ratio;

    $dx = -($current_point->[0] - $data->{points}[0][0]);
    $dy = -($current_point->[1] - $data->{points}[0][1]);

    $d = $oldy;
    $ratio = $d / $parametrization->[$i];

    $point->[0] += -$dy * $ratio;
    $point->[1] +=  $dx * $ratio;
  }

  elsif ($data->{type} eq "curve-to") {
    $ratio = $d / $parametrization->[$i];

    $point->[0] =       $current_point->[0] * (1 - $ratio) * (1 - $ratio) * (1 - $ratio)
                + 3 * $data->{points}[0][0] * (1 - $ratio) * (1 - $ratio) * $ratio
                + 3 * $data->{points}[1][0] * (1 - $ratio) * $ratio       * $ratio
                + 3 * $data->{points}[2][0] * $ratio       * $ratio       * $ratio;
    $point->[1] =       $current_point->[1] * (1 - $ratio) * (1 - $ratio) * (1 - $ratio)
                + 3 * $data->{points}[0][1] * (1 - $ratio) * (1 - $ratio) * $ratio
                + 3 * $data->{points}[1][1] * (1 - $ratio) * $ratio       * $ratio
                + 3 * $data->{points}[2][1] * $ratio       * $ratio       * $ratio;

    $dx =-3 *   $current_point->[0] * (1 - $ratio) * (1 - $ratio)
        + 3 * $data->{points}[0][0] * (1 - 4 * $ratio + 3 * $ratio * $ratio)
        + 3 * $data->{points}[1][0] * (    2 * $ratio - 3 * $ratio * $ratio)
        + 3 * $data->{points}[2][0] * $ratio * $ratio;
    $dy =-3 *   $current_point->[1] * (1 - $ratio) * (1 - $ratio)
        + 3 * $data->{points}[0][1] * (1 - 4 * $ratio + 3 * $ratio * $ratio)
        + 3 * $data->{points}[1][1] * (    2 * $ratio - 3 * $ratio * $ratio)
        + 3 * $data->{points}[2][1] * $ratio * $ratio;

    $d = $oldy;
    $ratio = $d / sqrt ($dx * $dx + $dy * $dy);

    $point->[0] += -$dy * $ratio;
    $point->[1] +=  $dx * $ratio;
  }
}

sub map_path_onto {
  my ($cr, $path) = @_;

  my $param = {
    path => $path,
    parametrization => parametrize_path ($path),
  };

  my $current_path = $cr->copy_path;
  transform_path ($current_path, \&point_on_path, $param);

  $cr->new_path;
  $cr->append_path ($current_path);
}


sub draw_path {
  my ($cr) = @_;
  $cr->move_to (50, 700);
  $cr->line_to (300, 750);
  $cr->curve_to (550, 800, 900, 700, 900, 400);
  $cr->curve_to (900, 0, 600, 300, 100, 100);
}

sub draw_text {
  my ($cr) = @_;

  my $font_options = Cairo::FontOptions->create;

  $font_options->set_hint_style ("none");
  $font_options->set_hint_metrics ("off");

  $cr->set_font_options ($font_options);

  my $layout = Pango::Cairo::create_layout ($cr);

  my $desc = Pango::FontDescription->from_string ("Serif 72");
  $layout->set_font_description ($desc);

  $layout->set_text ("It was a dream... Oh Just a dream...");

  my $line = $layout->get_line (0);

  Pango::Cairo::layout_line_path ($cr, $line);
}

sub draw {
  my ($cr) = @_;

  # Decrease tolerance a bit, since it's going to be magnified
  $cr->set_tolerance (0.05);

  $cr->set_source_rgb (1.0, 0.0, 0.0);
  draw_path ($cr);
  fancy_cairo_stroke_preserve ($cr);

  my $path = $cr->copy_path_flat;

  $cr->new_path;

  draw_text ($cr);
  map_path_onto ($cr, $path);
  $cr->set_source_rgba (0.3, 0.3, 1.0, 0.3);
  $cr->fill_preserve;
  $cr->set_source_rgb (0.1, 0.1, 0.1);
  $cr->stroke;
}

{
  if ($#ARGV != 0) {
    warn "Usage: cairo-twisted-text.pl OUTPUT_FILENAME\n";
    exit 1;
  }

  my $filename = $ARGV[0];

  my $surface = Cairo::ImageSurface->create ("argb32", 500, 500);
  my $cr = Cairo::Context->create ($surface);

  $cr->translate (0, 50);
  $cr->scale (0.5, 0.5);

  $cr->set_source_rgb (1.0, 1.0, 1.0);
  $cr->paint;
  draw ($cr);

  if ("success" ne $surface->write_to_png ($filename)) {
    warn "Could not save png to '$filename'\n";
    exit 1;
  }

  exit 0;
}
