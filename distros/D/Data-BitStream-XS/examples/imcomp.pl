#!/usr/bin/perl
use strict;
use warnings;
use FindBin;  use lib "$FindBin::Bin/../lib";
use Data::BitStream::XS;
use Getopt::Long;
use Storable qw(dclone);
use List::Util qw(sum);
use POSIX;
use Imager;

our $have_c;
BEGIN {
  eval {
    require Inline::Files;
    require Inline;  Inline->import(qw(C));
    $have_c = 1;
    1;
  } or do {
    warn "Inline.pm not installed, using Pure Perl for decor/predict\n";
    $have_c = 0;
  }
}

#
# Simple example lossless image compressor.
#
# I've added a variety of predictors and a couple decorrelation transforms
# both for better compression, and to make the program interesting as a
# vehicle for experimenting with different ideas.
#
# Examples:
#
#  Compress art.ppm -> c.bsc using defaults
#
#      perl imcomp.pl  -c  -i art.ppm  -o c.bsc
#
#  Compress art.ppm -> c.bsc with custom settings
#
#      perl imcomp.pl  -c  -predict gap  -transform rct \
#                          -code 'startstop(0-1-2-3-3-3-3)' \
#                          -i art.ppm  -o c.bsc
#
#  Decompress c.bsc -> c.ppm
#
#   perl imcomp.pl  -d  -i c.bsc  -o c.ppm
#
# Note: This is for demonstration.  It runs ~100x slower than similar C code,
# and it is quite a bit simpler than systems like JPEG-LS, CALIC, JPEG2000,
# HDPhoto, etc.  It will typically beat gzip, bzip2, lzma however, and on many
# inputs it will compress better than JPEG-LS (mostly because of the color
# transform).  Sometimes it beats PNG, other times not.
# The speed can be improved with some work, mostly in the Data::BitStream
# library.
#
# BUGS / TODO:
#       - encoding method is simplistic
#       - Run mode is making most photo images bigger than not using it.  That
#         is, simple output is smaller than complex on photo images, though on
#         smoother images (such as almost any print raster) complex mode will
#         be far better.  This indicates some more thought is needed in how
#         we handle the runs vs. literals.
#       - contexts with bias correction would help
#       - Should read from stdin and write to stdout if desired.

my %transform_info = (
  'YCOCG' => [ 'YCoCg', \&decorrelate_YCoCg, \&correlate_YCoCg ],
  'RCT'   => [ 'RCT',   \&decorrelate_RCT,   \&correlate_RCT   ],
  'RGB'   => [ 'RGB',   undef,               undef             ],
);

my %predictor_info = (
  '1D'    => \&predict_1d,
  'DARC'  => \&predict_darc,
  'MED'   => \&predict_med,
  'GAP'   => \&predict_gap,
  'DJMED' => \&predict_djmed,
  'GED2'  => \&predict_ged2,
);

if ($have_c) {
  $predictor_info{'MED'} = \&c_predict_med;
  $transform_info{'YCOCG'} = [ 'YCoCg',
                               \&c_decorrelate_YCoCg,
                               \&c_correlate_YCoCg ];
}

my $min_runlen_param = 3;   # Parameter for RLE in compression

sub die_usage {
  my $usage =<<EOU;
Usage:
         -c                compress
         -d                decompress
         -i <file>         input file  (image for compress, bsc for decompress)
         -o <file>         output file (image for decompress, bsc for compress)

    Optional arguments for compression:

         [-code <code>]    encoding method for pixel deltas:
                               Gamma (default), Delta, Omega, Fibonacci,
                               EvenRodeh, Levenstein, FibC2, ARice(n),
                               Rice(n), Golomb(n), GammaGolomb(n), ExpGolomb(n),
                               StartStop(#-#-...), etc.
         [-transform <tf>] use a lossless color transform for color images:
                               YCoCg  Malvar   (default)
                               RCT    JPEG2000
                               RGB    No transform
         [-predict <pred>] use a particular pixel prediction method
                               MED    JPEG-LS MED (default)
                               DARC   Memon/Wu simple
                               GAP    CALIC gradient
                               GED2   Avramović / Savić
                               DJMED  median of linear predictors
         [-norun]          perform simpler coding that doesn't look for runs
EOU

  die $usage;
}

my %opts = (
            'help|usage|?' => sub { die_usage() },
          );
GetOptions( \%opts,
           'help|usage|?',
           'c',
           'd',
           'norun',
           'i=s',
           'o=s',
           'code=s',
           'predict=s',
           'transform=s',
          ) or die_usage;

die_usage if !defined $opts{'c'} && !defined $opts{'d'};
die_usage unless defined $opts{'i'} && defined $opts{'o'};
die_usage if defined $opts{'c'} && defined $opts{'d'};

if (defined $opts{'c'}) {
  compress_file( $opts{'i'},
                 $opts{'o'},
                 $opts{'code'}          || 'ARice(2)',
                 uc ($opts{'predict'}   || 'MED'),
                 uc ($opts{'transform'} || 'YCoCg'),
               );
} else {
  decompress_file( $opts{'i'}, $opts{'o'} );
}


###############################################################################
#
#              Pixel Predictors
#
###############################################################################
sub predict_1d {
  my ($colors, $y, $x, $p, $width) = @_;

  return 0 if $x == 0 && $y == 0;
  return $colors->[$y-1][$x  ][$p] if $x == 0;
  return $colors->[$y  ][$x-1][$p];
}

sub predict_darc {
  my ($colors, $y, $x, $p, $width) = @_;
  return predict_1d(@_) if $x == 0 || $y == 0;

  my $w  = $colors->[$y  ][$x-1][$p];
  my $n  = $colors->[$y-1][$x  ][$p];
  my $nw = $colors->[$y-1][$x-1][$p];

  my $gv = abs($w - $nw);
  my $gh = abs($n - $nw);
  return $n if $gv + $gh == 0;
  my $alpha = $gv / ($gv + $gh);
  return POSIX::floor( $alpha * $w + (1-$alpha) * $n );
}

# MED (Median Edge Detection) from LOCO-I / JPEG-LS
sub predict_med {
  my ($colors, $y, $x, $p, $width) = @_;
  return predict_1d(@_) if $x == 0 || $y == 0;

  my $w  = $colors->[$y  ][$x-1][$p];
  my $n  = $colors->[$y-1][$x  ][$p];
  my $nw = $colors->[$y-1][$x-1][$p];

  my ($minwn, $maxwn) = ($n > $w)  ?  ($w, $n)  :  ($n, $w);
  return $minwn if $nw >= $maxwn;
  return $maxwn if $nw <= $minwn;
  return $n + $w - $nw;
}

# GAP (Gradient Adjusted Predictor) from CALIC
sub predict_gap {
  my ($colors, $y, $x, $p, $width) = @_;
  return predict_med(@_) if $y <= 1 || $x <= 1 || $x == $width-1;

  my $w  = $colors->[$y  ][$x-1][$p];
  my $n  = $colors->[$y-1][$x  ][$p];
  my $nw = $colors->[$y-1][$x-1][$p];
  my $ww = $colors->[$y  ][$x-2][$p];
  my $ne = $colors->[$y-1][$x+1][$p];
  my $nn = $colors->[$y-2][$x  ][$p];
  my $nne= $colors->[$y-2][$x+1][$p];

  my $dh = abs($w - $ww) + abs($n - $nw) + abs($ne - $n);
  my $dv = abs($w - $nw) + abs($n - $nn) + abs($ne - $nne);
  return $n if $dh - $dv > 80;
  return $w if $dv - $dh > 80;
  my $pred = ($w + $n)/2 + ($ne - $nw)/4;
  if    ($dh-$dv > 32) { $pred = (  $pred + $n) / 2; }
  elsif ($dv-$dh > 32) { $pred = (  $pred + $w) / 2; }
  elsif ($dh-$dv >  8) { $pred = (3*$pred + $n) / 4; }
  elsif ($dv-$dh >  8) { $pred = (3*$pred + $w) / 4; }
  return POSIX::floor($pred);
}

# DJMED (Median of three linear predictors)
sub predict_djmed {
  my ($colors, $y, $x, $p, $width) = @_;
  return predict_med(@_) if $y <= 1 || $x <= 1;

  my $w  = $colors->[$y  ][$x-1][$p];
  my $n  = $colors->[$y-1][$x  ][$p];
  my $nw = $colors->[$y-1][$x-1][$p];
  my $ww = $colors->[$y  ][$x-2][$p];
  my $nn = $colors->[$y-2][$x  ][$p];

  my $T = 32;
  my $gv = abs($nw - $w) + abs($nn - $n);
  my $gh = abs($ww - $w) + abs($nw - $n);
  return $w if ($gv-$gh) >  $T;
  return $n if ($gv-$gh) < -$T;

  # predict the median of three linear predictors
  my $p1 = $n + $w - $nw;
  my $p2 = $n - ($nn - $n);
  my $p3 = $w - ($ww - $w);
  my $pred = ( $p1<$p2 ? ($p2<$p3 ? $p2 : ($p1<$p3 ? $p3 : $p1))
                       : ($p3<$p2 ? $p2 : ($p3<$p1 ? $p3 : $p1)) );
  return $pred;
}

sub predict_ged2 {
  my ($colors, $y, $x, $p, $width) = @_;
  return predict_med(@_) if $y <= 1 || $x <= 1;

  my $w  = $colors->[$y  ][$x-1][$p];
  my $n  = $colors->[$y-1][$x  ][$p];
  my $nw = $colors->[$y-1][$x-1][$p];
  my $ww = $colors->[$y  ][$x-2][$p];
  my $nn = $colors->[$y-2][$x  ][$p];

  my $T = 8;
  my $gv = abs($nw - $w) + abs($nn - $n);
  my $gh = abs($ww - $w) + abs($nw - $n);
  return $w if ($gv-$gh) >  $T;
  return $n if ($gv-$gh) < -$T;
  return ($n + $w - $nw);
}


###############################################################################
#
#              Color Transforms for decorrelation
#
###############################################################################

# It would be great to just use Imager's matrix convert for the color
# transforms, but it clamps the results to 0-255, which makes it useless.
# Too bad, because it's easy and fast.

# RCT: JPEG2000 lossless integer
sub decorrelate_RCT {
  my $rcolors = shift;
  die unless scalar @{$rcolors->[0]} == 3;

  map { my ($r, $g, $b) = @{$_};
        my $Y  = POSIX::floor( ($r + 2*$g + $b) / 4 );
        my $Cb = $r - $g;
        my $Cr = $b - $g;
        [ ($Y,$Cb,$Cr) ];
      } @{$rcolors};
}
sub correlate_RCT {
  my $rcolors = shift;
  die unless scalar @{$rcolors->[0]} == 3;

  map { my ($Y, $Cb, $Cr) = @{$_};
        my $g = $Y - POSIX::floor( ($Cb+$Cr)/4 );
        my $r = $Cb + $g;
        my $b = $Cr + $g;
        [ ($r,$g,$b) ];
      } @{$rcolors};
}

# YCoCg: Malvar's lossless version from his 2008 SPIE lifting paper
sub decorrelate_YCoCg {
  my $rcolors = shift;
  die unless scalar @{$rcolors->[0]} == 3;

  map { my ($r, $g, $b) = @{$_};
        my $Co = $r - $b;
        my $t  = $b + int( (($Co < 0) ? $Co-1 : $Co) / 2 );
        my $Cg = $g - $t;
        my $Y  = $t + int( (($Cg < 0) ? $Cg-1 : $Cg) / 2 );
        [ ($Y,$Co,$Cg) ];
      } @{$rcolors};
}
sub correlate_YCoCg {
  my $rcolors = shift;
  die unless scalar @{$rcolors->[0]} == 3;

  map { my ($Y, $Co, $Cg) = @{$_};
        my $t = $Y - int( (($Cg < 0) ? $Cg-1 : $Cg) / 2 );
        my $g = $Cg + $t;
        my $b = $t - int( (($Co < 0) ? $Co-1 : $Co) / 2 );
        my $r = $b + $Co;
        [ ($r,$g,$b) ];
      } @{$rcolors};
}
sub c_decorrelate_YCoCg {
  my $rcolors = shift;
  die unless scalar @{$rcolors->[0]} == 3;
  map { [RGB_to_YCoCg(@{$_})] } @{$rcolors};
}
sub c_correlate_YCoCg {
  my $rcolors = shift;
  die unless scalar @{$rcolors->[0]} == 3;
  map { [YCoCg_to_RGB(@{$_})] } @{$rcolors};
}


###############################################################################
#
#              Windowed Bias Calculator (not used)
#
###############################################################################
{
  my $param_window_size;
  my @sums;  # one sum per context
  my @vals;  # vals[$context]->[...]
  my @context_init;

  sub init_bias {
    my $context = shift;
    if (!defined $context_init[$context]) {
      $param_window_size = 50;
      $sums[$context] = 0;
      @{$vals[$context]} = ();
      $context_init[$context] = 1;
    }
 }

  sub bias {
    my $context = shift;
    my $newval = shift;

    init_bias($context) unless defined $context_init[$context];

    my $nvals = scalar @{$vals[$context]};
    my $bias = ($nvals == 0) ? 0 : sprintf("%.0f", $sums[$context] / $nvals);

    push @{$vals[$context]}, $newval;
    $sums[$context] += $newval;

    if ($nvals == $param_window_size) {
      $sums[$context] -= shift @{$vals[$context]};
    }
    die "vals error" if scalar @{$vals[$context]} > $param_window_size;
    die "sum error" unless $sums[$context] == sum @{$vals[$context]};

    return $bias;
  }
}

###############################################################################
#
#              Compression internals, both super-simple and more complex
#
###############################################################################
sub compress_simple {
  my ($stream, $code, $rcolors, $y, $width, $p, $predict_sub) = @_;

  my @pixels  = map { $_->[$p] } @{$rcolors->[$y  ]};
  my @deltas;

  foreach my $x (0 .. $width-1) {
    # 1) Predict this pixel.
    my $predict = $predict_sub->($rcolors, $y, $x, $p, $width);
    # 2) encode the delta mapped to an unsigned number
    push @deltas, $pixels[$x] - $predict;
    #my $udelta = ($delta >= 0)  ?  2*$delta  :  -2*$delta-1;
  }
  my @udeltas = map { $_ >= 0  ?  2*$_  :  -2*$_-1 } @deltas;
  $stream->code_put($code, @udeltas);
}

sub decompress_simple {
  my ($stream, $code, $rcolors, $y, $width, $p, $predict_sub) = @_;

  # get a line worth of absolute deltas and convert them to signed
  my @deltas = map { (($_&1) == 0)  ?  $_ >> 1  :  -(($_+1) >> 1); }
               $stream->code_get($code, $width);
  die "short code read" unless scalar @deltas == $width;

  foreach my $x (0 .. $width-1) {
    my $predict = $predict_sub->($rcolors, $y, $x, $p, $width);
    my $pixel = $predict + $deltas[$x];
    $rcolors->[$y][$x][$p] = $pixel;
  }
}

sub compress_complex {
  my ($stream, $code, $rcolors, $y, $width, $p, $predict_sub) = @_;

  my @pixels  = map { $_->[$p] } @{$rcolors->[$y  ]};
  my @deltas;

  my $x = 0;
  while ($x < $width) {
    my $px = $pixels[$x];
    my $litlen = 0;
    my $runlen = 1;
    my $is_lit;

    # Search for a horizontal run
    $runlen++ while ($x+$runlen) < $width && $px == $pixels[$x+$runlen];
    if ($runlen >= $min_runlen_param) {
      $is_lit = 0;
      {
        my $predict = $predict_sub->($rcolors, $y, $x, $p, $width);
        push @deltas, $px - $predict;
      }
      $x += $runlen;
    } else {
      $is_lit = 1;
      my $litstart = $x;
      # The runlength break tests aren't very good, but provide a bit of a
      # balance between low entropy (smooth) and high entropy (photo) images.
      my $breaklen = $min_runlen_param;
      while ( ($x+$breaklen) < $width) {
        $x++;
        next if $pixels[$x] != $pixels[$x+1];
        if ($pixels[$x] != $pixels[$x+2]) { $x++; next; }
        # we have two matching pixels, see how many we will get
        $breaklen = $min_runlen_param;
        { my $nlits = ($x-$litstart) >> 3; $breaklen++ while ($nlits >>= 1); }
        $runlen = 3;
        $runlen++ while ($x+$runlen) < $width &&
                        $pixels[$x] == $pixels[$x+$runlen] &&
                        $runlen < $breaklen;
        # If we found enough, exit
        last if $runlen >= $breaklen;
      }
      $x = $width if ($x+$breaklen) >= $width;
      $litlen = $x - $litstart;
      foreach my $lx ($litstart .. $x-1) {
        my $predict = $predict_sub->($rcolors, $y, $lx, $p, $width);
        push @deltas, $pixels[$lx] - $predict;
      }
    }
    $stream->write(1, $is_lit); # indicate if this is a run or literal
    if ($is_lit) {
      $stream->put_gamma($litlen-1);
    } else {
      $stream->put_gamma($runlen-$min_runlen_param);
    }
  }

  # We could perform context-based biasing here, something like:
  #
  # @deltas = map { $_ - bias($context, $_) } @deltas;
  #
  # though we'd want the context adjusting as we go.  This helps center
  # the predictions around 0.

  my @udeltas = map { $_ >= 0  ?  2*$_  :  -2*$_-1 } @deltas;
  $stream->code_put($code, @udeltas);
}

sub decompress_complex {
  my ($stream, $code, $rcolors, $y, $width, $p, $predict_sub) = @_;

  my $pixels = 0;
  my $ndeltas = 0;
  my @interp;
  while ($pixels < $width) {
    my $is_lit = $stream->read(1);
    my $length = $stream->get_gamma;
    if ($is_lit) {
      $length += 1;
      $ndeltas += $length;
      $pixels += $length;
    } else {
      $length += $min_runlen_param;
      $ndeltas += 1;
      $pixels += $length;
    }
    push @interp, [ $is_lit, $length ];
  }

  # get a line worth of absolute deltas and convert them to signed
  my @deltas = map { (($_&1) == 0)  ?  $_ >> 1  :  -(($_+1) >> 1); }
               $stream->code_get($code, $ndeltas);
  die "short code read" unless scalar @deltas == $ndeltas;

  my $x = 0;
  while (scalar @interp > 0) {
    my ($is_lit, $length) = @{shift @interp};
    if (!$is_lit) {
      my $predict = $predict_sub->($rcolors, $y, $x, $p, $width);
      my $pixel = $predict + shift @deltas;
      $rcolors->[$y][$x++][$p] = $pixel  for (1 .. $length);
    } else {
      my $last_x = $x + $length;
      while ($x < $last_x) {
        my $predict = $predict_sub->($rcolors, $y, $x, $p, $width);
        my $pixel = $predict + shift @deltas;
        $rcolors->[$y][$x][$p] = $pixel;
        $x++;
      }
    }
  }
}

###############################################################################
#
#              Image Compression
#
###############################################################################

sub compress_file {
  my($infile, $outfile, $code, $predictor, $transform) = @_;

  # Use Imager to get the file
  my $image = Imager->new;
  my $idata;
  $image->read( file => $infile,  data => \$idata)  or die $image->errstr;
  # Image header:
  my ($width, $height, $planes, $mask) = $image->i_img_info;

  $transform = 'RGB' unless $planes > 1;
  my $trans_data = $transform_info{$transform};
  die "Unknown transform: $transform" unless defined $trans_data;
  my $trans_name = $trans_data->[0];  # Canonical name
  my $decor_sub  = $trans_data->[1];  # decorrelation sub

  my $predict_sub = $predictor_info{$predictor};
  die "Unknown predictor: $predictor" unless defined $predict_sub;

  my $method = "$code/$predictor";
  $method .= "/$trans_name" if $planes > 1;

  # Start up the stream
  my $stream = Data::BitStream::XS->new(
        file => $outfile,
        fheader => "BSC $method w$width h$height p$planes",
        mode => 'w' );

  my @colors;   # [$y]->[$x]->[$p]
  foreach my $y (0 .. $height-1) {
    $colors[$y-3] = undef if $y >= 3;   # remove unneeded y values

    {
      # Put a scanline worth of colors into the @colors array
      if ($planes == 1) {
        my @samples = $image->getsamples( y => $y,
                                          channels => [0],
                                          type => '8bit' );
        @{$colors[$y]} = map { [$_] } @samples;
      } else {
        my @s0 = $image->getsamples( y => $y,
                                     channels => [0],
                                     type => '8bit' );
        my @s1 = $image->getsamples( y => $y,
                                     channels => [1],
                                     type => '8bit' );
        my @s2 = $image->getsamples( y => $y,
                                     channels => [2],
                                     type => '8bit' );
        @{$colors[$y]} = map { [$s0[$_], $s1[$_], $s2[$_]] } (0 .. $width-1);
      }
    }

    # Decorrelate the color planes for better compression
    @{$colors[$y]} = $decor_sub->($colors[$y]) if defined $decor_sub;

    foreach my $p (0 .. $planes-1) {
      if ($opts{'norun'}) {
        compress_simple($stream, $code, \@colors, $y, $width, $p, $predict_sub);
      } else {
        compress_complex($stream,$code, \@colors, $y, $width, $p, $predict_sub);
      }
    }
  }

  # Close the stream, which will flush the file
  $stream->write_close;
  my $origsize = $width * $height * $planes;
  my $compsize = int( ($stream->len + 7) / 8);
  printf "origsize: %d   %s compressed size: %d   ratio %.1fx\n",
         $origsize, $method, $compsize, $origsize / $compsize;
}


###############################################################################
#
#              Image Decompression
#
###############################################################################

sub decompress_file {
  my($infile, $outfile) = @_;

  # Open the bitstream file with one header line
  my $stream = Data::BitStream::XS->new( file => $infile,
                                     fheaderlines => 1,
                                     mode => 'ro' );

  # Parse the header line
  my $header = $stream->fheader;
  die "$infile is not a BSC compressed image\n" unless $header =~ /^BSC /;

  my ($method, $width, $height, $planes) =
              $header =~ /^BSC (\S+) w(\d+) h(\d+) p(\d+)/;
  print "$width x $height x $planes image compressed with $method encoding\n";

  my ($code, $predictor, $transform) = split('/', $method);
  die "No code found in header" unless defined $code;
  die "No predictor found in header" unless defined $predictor;
  die "No transform found in header" unless $planes == 1 || defined $transform;

  # Set up transform
  my $cor_sub;
  if (defined $transform) {
    die "Unknown transform: $transform" unless defined $transform_info{uc $transform};
    $cor_sub = $transform_info{uc $transform}->[2];
  }

  my $predict_sub = $predictor_info{$predictor};
  die "Unknown predictor: $predictor" unless defined $predict_sub;

  # Start up an Imager object
  my $image = Imager->new( xsize    => $width,
                           ysize    => $height,
                           channels => $planes);

  my @colors;   # [$y]->[$x]->[$p]
  foreach my $y (0 .. $height-1) {
    $colors[$y-3] = undef if $y >= 3;   # remove unneeded y values

    foreach my $p (0 .. $planes-1) {
      if ($opts{'norun'}) {
        decompress_simple($stream, $code, \@colors, $y,$width,$p, $predict_sub);
      } else {
        decompress_complex($stream,$code, \@colors, $y,$width,$p, $predict_sub);
      }
    }

    # Set the scanline.
    {
      # Transform back into RGB from YUV/YCbCr/YCoCg/etc. if necessary
      my @ycolors = (defined $cor_sub) ? $cor_sub->($colors[$y])
                                       : @{$colors[$y]};
      if ($planes == 1) {
        $image->setscanline( y => $y,  type => '8bit', pixels =>
           pack("C*", map { $_->[0], $_->[0], $_->[0], 0 } @ycolors) );
      } else {
        $image->setscanline( y => $y,  type => '8bit', pixels =>
           pack("C*", map { $_->[0], $_->[1], $_->[2], 0 } @ycolors) );
      }
    }
  }

  # Write the final image
  $image->write( file => $outfile )  or die $image->errstr;
}

__END__

__C__

/*
 * The default decorrelation and predictors in C.
 * They're only a few lines each, and this makes a big difference in speed
 * because they're called once per pixel (sometimes less for the predictor).
 * On my machine the compression/decompression runs about 1.8x faster.
 */

void RGB_to_YCoCg(int r, int g, int b) {
  int t, Y, Co, Cg;
  Inline_Stack_Vars;

  Co = r - b;
  t = b + (((Co < 0) ? Co-1 : Co)/2);
  Cg = g - t;
  Y = t + (((Cg < 0) ? Cg-1 : Cg)/2);

  Inline_Stack_Reset;
  Inline_Stack_Push(sv_2mortal(newSViv( Y  )));
  Inline_Stack_Push(sv_2mortal(newSViv( Co )));
  Inline_Stack_Push(sv_2mortal(newSViv( Cg )));
  Inline_Stack_Done;
}

void YCoCg_to_RGB(int Y, int Co, int Cg) {
  int t, r, g, b;
  Inline_Stack_Vars;

  t = Y - (((Cg < 0) ? Cg-1 : Cg)/2);
  g = Cg + t;
  b = t - (((Co < 0) ? Co-1 : Co)/2);
  r = b + Co;

  Inline_Stack_Reset;
  Inline_Stack_Push(sv_2mortal(newSViv( r )));
  Inline_Stack_Push(sv_2mortal(newSViv( g )));
  Inline_Stack_Push(sv_2mortal(newSViv( b )));
  Inline_Stack_Done;
}

static int getcolor(SV* rcolors, int y, int x, int p) {
  if ( (!rcolors) || (!SvROK(rcolors)) || (SvTYPE(SvRV(rcolors)) != SVt_PVAV) )
    croak("getcolor: rcolors isn't an array");
  AV* colors = (AV*)SvRV(rcolors);
  SV** yc = av_fetch(colors, y, 0);
  if ( (!yc) || (!SvROK(*yc)) || (SvTYPE(SvRV(*yc)) != SVt_PVAV) )
    croak("getcolor: rcolors->[y] isn't an array");
  AV* xcolors = (AV*)SvRV(*yc);
  SV** xc = av_fetch(xcolors, x, 0);
  if ( (!xc) || (!SvROK(*xc)) || (SvTYPE(SvRV(*xc)) != SVt_PVAV) )
    croak("getcolor: rcolors->[y][x] isn't an array");
  AV* pcolors = (AV*)SvRV(*xc);
  SV** pc = av_fetch(pcolors, p, 0);
  if (pc == 0)
    croak("getcolor: rcolors->[y][x][p] isn't an value");
  int value = SvIV(*pc);
  return value;
}

int c_predict_med(SV* rcolors, int y, int x, int p, int width) {
  if ((x == 0) && (y == 0))  return 0;
  if (x == 0)                return getcolor(rcolors, y-1, x, p);
  if (y == 0)                return getcolor(rcolors, y, x-1, p);

  int w  = getcolor(rcolors, y  , x-1, p);
  int n  = getcolor(rcolors, y-1, x  , p);
  int nw = getcolor(rcolors, y-1, x-1, p);

  int minwn = (n > w) ? w : n;
  int maxwn = (n > w) ? n : w;
  if (nw >= maxwn)  return minwn;
  if (nw <= minwn)  return maxwn;
  return n + w - nw;
}
