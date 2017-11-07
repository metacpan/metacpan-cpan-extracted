#!/usr/bin/perl -w

# Copyright 2007, 2009, 2010, 2011, 2016, 2017 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Getopt::Long;
use List::Util qw(min max);
use POSIX qw(floor ceil);

my $option_verbose = 0;
my $option_txt = 1;
my $option_png = 1;
my $option_eps = 0;


GetOptions ('eps' => sub {
              $option_eps = 1;
              $option_png = 0;
              $option_txt = 0;
            })
  or exit 1;


#-----------------------------------------------------------------------------
# misc

sub write_file {
  my ($filename, $content) = @_;
  open my $out, '>', $filename or die;
  print $out $content or die;
  close $out or die;
}

#-----------------------------------------------------------------------------
# text graph

# (define (multiple? n d)
#   (integer? (/ n d)))

sub text_plot {
  my ($basename, $data) = @_;

  my $y_zero_pos = 20;
  my $x_step     = (@$data < 30 ? 2 : 1);
  my $x_max      = @$data + 3;
  my $width      = $x_step * ($x_max + 1);
  my $data_max   = max (@$data);
  my $data_min   = min (@$data);
  my $data_range = $data_max - $data_min;

  $data_max     += $data_range * 0.05;
  $data_min     -= $data_range * 0.05;
  $data_range = $data_max - $data_min;

  my $y_factor     = ($data_range < 11 ? 2.0
                      : $data_range < 22 ? 1.0
                      : 0.5);
  my $y_tick_step  = ($y_factor >= 2.0 ? 2
                      : $y_factor >= 1.0 ? 5
                      : 10);
  my $out_x_base = -4;
  my $out_y_base = -30;
  my @out;
  #   foreach my $out            (make_array #\space '(_4 75) '(_30 60))))

  my $setchar = sub {
    my ($x, $y, $char) = @_;
    $out[$y - $out_y_base][$x - $out_x_base] = $char;
  };
  my $setstr = sub {
    my ($x, $y, $str) = @_;
    for (my $i = 0; $i < length($str); $i++) {
      $setchar->($x+$i, $y, substr($str, $i, 1));
    }
  };
  my $scale_y = sub {
    my ($ydat) = @_;
    return $y_zero_pos + ceil($y_factor * $ydat);
  };
  my $scale_x = sub {
    my ($x) = @_;
    return $x * $x_step + floor(0.5 * $x_step);
  };

  # horizontal axis
  foreach my $i ($scale_x->(0) - 1 .. $width) {
    $setchar->($i, $scale_y->(0), '-');
  }

  # horizontal ticks
  foreach my $x (0 .. $x_max) {
    if (($x % 5) == 0) {
      $setchar->($scale_x->($x), $scale_y->(0), '+');
    }
  }

  # horizontal scale numbers
  foreach my $x (0 .. $x_max) {
    if (($x % 5) == 0
        && ($data->[$x]//0) >= 0) {
      $setstr->($scale_x->($x), $scale_y->(0) - 1, $x);
    }
  }

  # data
  foreach my $x (0 .. $#$data) {
    my $ydat = $data->[$x];
    my $ypos = $scale_y->($ydat);
    if ($ydat < 0) {
      for (my $j = $scale_y->(0); $j >= $ypos; $j--) {
        $setchar->($scale_x->($x), $j, '*');
      }
    } else {
      for (my $j = $scale_y->(0); $j <= $ypos; $j++) {
        $setchar->($scale_x->($x), $j, '*');
      }
    }
  }

  # vertical axis, positive
  { my $y = 0;
    for ( ; $y < $data_max + 0.1 * $data_range; $y += 0.5) {
      $setchar->(-1, $scale_y->($y), '|');
    }
    $setchar->(-3, $scale_y->($y) - 1, '%');
  }

  # vertical scale numbers, positive
  for (my $y = 0; $y < $data_max + 0.1 * $data_range; $y += $y_tick_step) {
    $setchar->(-1, $scale_y->($y), '+');
    $setstr->(-4, $scale_y->($y), sprintf("%2.0f", $y));
  }

  # vertical axis, negative
  if (List::Util::first {$_ < 0} @$data) {
    # vertical axis, negative
    for (my $y = 0; $y > $data_min; $y -= 0.5) {
      $setchar->(-1, $scale_y->($y), '|');
    }

    # vertical scale ticks, negative
    for (my $y = 0; $y > $data_min; $y -= $y_tick_step) {
      $setchar->(-1, $scale_y->($y), '+');
    }
  }

  my $str;
  foreach my $row (reverse @out) {
    if (defined $row) {
      $str .= join ('', map {$_ // ' '} @$row);
    }
    $str .= "\n";
  }
  $str =~ s/ +\n/\n/g;
  $str =~ s/^\n+//;
  $str =~ s/\n+$/\n/;

  if ($option_verbose) {
    print $str;
  }
  write_file ("$basename.txt", $str);
}
# foreach my
#     (let ((lst (array_>list out)))
#       (set! lst (apply zip lst))
#       (set! lst (map! list_>string lst))
#       (set! lst (reverse! lst))
#       (set! lst (map! string_trim_right lst))
#       (set! lst (drop_while string_null? lst))
#       (set! lst (drop_right_while string_null? lst))
#
#       (let ((str (string_join lst "\n" 'suffix)))
# 	(if option_verbose
# 	    (display str))
# 	(call_with_output_file (string_append basename ".txt")
# 	  (lambda (port)
# 	    (display str port)))))))


# (define data '(1 2 3 4 5 6 7 6 5 4 0 0 0 0 0 0))
# (let ((total (apply + data)))
#   (set! data (map (lambda (x)
# 		    (* 100.0 (/ x total)))
# 		  data)))
# (dv data)
# (text_plot "foo" data)
# (exit 0)



#_____________________________________________________________________________

sub gnuplot_run {
  my ($basename, $data) = @_;
  print "gnuplot $basename\n";

  my $data_max   = max (@$data);
  my $data_min   = min (@$data);
  my $data_range = $data_max - $data_min;

  my $xhigh      = @$data + 0.5;
  my $datafilename = "$basename.data";
  my $plotfilename = "weights.gnuplot";

  $data_max     += $data_range * 0.1;
  $data_min     -= $data_range * 0.1;
  $data_range = $data_max - $data_min;

  while (@$data && $data->[-1] == 0) {
    pop @$data;
  }
  write_file ($datafilename, join ('', map {; "$_\n"} @$data));

  # png
  #
  if ($option_png) {
    # something evil happens with "xtics axis", need dummy xlabel
    write_file ($plotfilename, <<"HERE");
set terminal png size 400,250

# there was some sort of incompatible change in gnuplot 4.2 forcing the
# ``offset'' keyword here, dunno if it works with older gnuplot too ...
set xlabel " " offset 0, -2
set xrange [-0.5:$xhigh]
set xtics axis 5
set mxtics 5

set yrange [$data_min:$data_max]
set format y "%.1f"

unset key
set style fill solid 1.0
set boxwidth 0.6 relative
plot "$datafilename" with boxes lc "red"
HERE

    system("gnuplot $plotfilename 2>&1 >$basename.png") == 0 or die;
  }

  # eps
  #
  if ($option_eps) {
    # something evil happens with "xtics axis", need dummy xlabel
    write_file ($plotfilename, <<"HERE");
set terminal postscript portrait

set xlabel " " offset 0, -2
set xrange [-0.5:$xhigh]
set xtics axis 5
set mxtics 5

set yrange [$data_min:$data_max]
set format y "%.1f"

unset key
set style fill solid 1.0
set boxwidth 0.6 relative
plot "$datafilename" with boxes
HERE

    system ("gnuplot $plotfilename 2>&1 >$basename.eps") == 0 or die;
  }

  unlink ($datafilename) or die;
  unlink ($plotfilename) or die;
}


sub mung_png {
  my ($filename, $title) = @_;
  require Image::ExifTool;

  # allow writing of extra png "Homepage" field, if not already setup
  { no warnings 'once';
    $Image::ExifTool::UserDefined
      {'Image::ExifTool::PNG::TextualData'}
        {'Homepage'} ||= {};
  }

  my $exif = Image::ExifTool->new;
  $exif->ExtractInfo($filename) or die;

  $exif->SetNewValue ('Title', $title);
  $exif->SetNewValue ('Author', 'Kevin Ryde');

  $exif->SetNewValue ('Copyright', <<'HERE');
Copyright 2007, 2009, 2010, 2011 Kevin Ryde

This file is part of Chart.

Chart is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License
along with Chart.  If not, see <http://www.gnu.org/licenses/>.
HERE

  $exif->SetNewValue ('CreationTime',
                      POSIX::strftime ('%a, %d %b %Y %H:%M:%S %z',
                                       localtime(time)));
  $exif->SetNewValue ('Software', 'Chart doc/weights.pl, and gnuplot');

  $exif->SetNewValue
    ('Homepage', 'http://user42.tuxfamily.org/chart/index.html');

  $exif->WriteInfo($filename) or die;
}

sub weights {
  my %opt = @_;
  my $description = $opt{'description'}
    || croak "weights: missing 'description'";
  my $basename = $opt{'basename'}
    || croak "weights: missing 'basename'";
  my $method = $opt{'method'};
  my $parameters = $opt{'parameters'} || [ $opt{'N'} ];
  my $show_count = $opt{'show_count'};
  # (proc (calc_proc count))

  my $warmup = 30 * $show_count;
  my @input = ((0) x $warmup,
               100,
               (0) x ($show_count - 1));

  my $in_series = ConstantSeries->new (array => \@input);
  my $ma_series = $in_series->$method (@$parameters);
  my $hi = $ma_series->hi;
  $ma_series->fill (0, $hi);

  my $output = $ma_series->array($opt{'array'}||'values');
  my @weights = @{$output}[$warmup .. $hi];

  if ($option_verbose) {
    print "$basename: ",Data::Dumper->Dump([\@weights],['weights']);
  }

  if (abs($weights[-1]) >= 1) {
    print "$basename: last weight $weights[-1]\n";
#    exit 1;
  }

  if ($option_txt) {
    text_plot ($basename, \@weights);
  }
  if ($option_png || $option_eps) {
    gnuplot_run ($basename, \@weights);
  }
  if ($option_png) {
    my $params = ($opt{'N'} ? "N=$opt{'N'}" : join(',', @$parameters));
    mung_png ("$basename.png", "$description, $params")
  }
}


#------------------------------------------------------------------------------

# weights (description => "MACD weights",
#          basename    => "chart-macd-weights",
#          method      => 'MACD',
#          parameters  => [12,26],
#          show_count  => 40);
# 
# weights (description => "MACD histogram weights",
#          basename    => "chart-macd-histogram-weights",
#          method      => 'MACD',
#          array       => 'histogram',
#          parameters  => [12,26,9],
#          show_count  => 40);


weights (description => "Exponential moving average weights",
         basename    => "chart-ema-weights",
         method      => 'EMA',
         N           => 15,
         show_count  => 30);

weights (description => "EMA of EMA weights",
         basename    => "chart-ema-2-weights",
         method      => sub {
           my ($parent, $N) = @_;
           return $parent->EMA($N)->EMA($N);
         },
         N           => 10,
         show_count  => 30);

weights (description => "EMA of EMA of EMA weights",
         basename    => "chart-ema-3-weights",
         method      => sub {
           my ($parent, $N) = @_;
           return $parent->EMA($N)->EMA($N)->EMA($N);
         },
         N           => 10,
         show_count  => 38);

weights (description => "Endpoint moving average weights",
         basename    => "chart-epma-weights",
         method      => 'EPMA',
         N           => 15,
         show_count  => 18);

weights (description => "Hull moving average weights",
         basename    => "chart-hull-weights",
         method      => 'HullMA',
         N           => 15,
         show_count  => 20);

weights (description => "Double-exponential moving average weights",
         basename    => "chart-dema-weights",
         method      => 'DEMA',
         N           => 20,
         show_count  => 40);

weights (description => "DEMA of DEMA of DEMA weights",
         basename    => "chart-dema-3-weights",
         method      => sub { $_[0]->DEMA($_[1])->DEMA($_[1])->DEMA($_[1]) },
         N           => 10,
         show_count  => 40);

weights (description => "Laguerre filter weights",
         basename    => "chart-laguerre-weights",
         method      => 'LaguerreFilter',
         N           => 0.2,
         show_count  => 40);

weights (description => "Regularized EMA weights",
         basename    => "chart-rema-weights",
         method      => 'REMA',
         N           => 15,  # with default lambda=0.5
         show_count  => 30);

weights (description => "Sine moving average weights",
         basename    => "chart-sine-weights",
         method      => 'SineMA',
         N           => 10,
         show_count  => 12);

weights (description => "T3 moving average weights",
         basename    => "chart-t3-weights",
         method      => 'T3',  # with default vf==0.7
         N           => 10,
         show_count  => 40);

weights (description => "Triangular moving average weights",
         basename    => "chart-tma-weights",
         method      => 'TMA',
         N           => 15,
         show_count  => 18);

weights (description => "Triple-exponential moving average weights",
         basename    => "chart-tema-weights",
         method      => 'TEMA',
         N           => 20,
         show_count  => 30);

weights (description => "Weighted moving average weights",
         basename    => "chart-wma-weights",
         method      => 'WMA',
         N           => 15,
         show_count  => 18);

weights (description => "Zero_lag exponential moving average weights",
         basename    => "chart-zlema-weights",
         method      => 'ZLEMA',
         N           => 15,
         show_count  => 20);

exit 0;


package ConstantSeries;
use strict;
use warnings;
use base 'App::Chart::Series';

sub new {
  my ($class, %option) = @_;
  my $array = delete $option{'array'} || die;
  $option{'hi'} = $#$array;
  $option{'name'} //= 'Const';
  $option{'timebase'} ||= do {
    require App::Chart::Timebase::Days;
    App::Chart::Timebase::Days->new_from_iso ('2008-07-23')
    };
  return $class->SUPER::new (arrays => { values => $array },
                             %option);
}
sub fill_part {}

__END__
