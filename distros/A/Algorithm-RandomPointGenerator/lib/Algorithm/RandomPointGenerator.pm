package Algorithm::RandomPointGenerator;

#---------------------------------------------------------------------------
# Copyright (c) 2014 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::RandomPointGenerator generates a set of random points in a 2D plane
# according to a user-specified probability distribution that is supplied as a
# 2D histogram.
# ---------------------------------------------------------------------------

use 5.10.0;
use strict;
use Carp;
use List::Util qw/reduce/;
use Math::Random;        
use constant PI => 4 * atan2( 1, 1 );
use Math::Big qw/euler/; 
use File::Basename;
use Graphics::GnuplotIF;     

our $VERSION = '1.01';

# from perl docs:
my $_num_regex =  '^[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$'; 
# Useful for creating reproducible results:
random_seed_from_phrase('hellojello');

# Constructor:
sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument " .
          "--- perhaps a misspelling\n" 
          if check_for_illegal_params(@params) == 0;
    bless {
        _hist_file           =>   $args{input_histogram_file}    || croak("histogram file required"),
        _bbox_file           =>   $args{bounding_box_file}       || croak("bounding box file required"),
        _N                   =>   $args{number_of_points}               || 2000,
        _how_many_to_discard =>   $args{how_many_to_discard}            || 500,
        _debug               =>   $args{debug}                          || 0,
        _proposal_density_width    =>   $args{proposal_density_width}   || 0.1, 
        _y_axis_pos_direction      =>   $args{y_axis_pos_direction}     || "down",
        _output_hist_bins_along_x  =>   $args{output_hist_bins_along_x} || 40,
        _command_line_mode         =>   $args{command_line_mode}        || 0,
        _x_delta             =>   undef,
        _y_delta             =>   undef,
        _input_histogram     =>   undef,
        _output_histogram    =>   undef,
        _bounding_box        =>   undef,
        _generated_points    =>   undef,
        _normalized_input_hist => undef,
        _sigmax_for_proposal_density => undef,
        _sigmay_for_proposal_density => undef,
        _bin_width_for_output_hist   => undef,
        _bin_height_for_output_hist  => undef,
    }, $class;
}

# The file that contains a 2D histogram of the desired probability distribution for
# the random points must either be in the CSV or the white-space-separated
# format. Since we are working with 2D densities, each line of this text file should
# show one row of the histogram.  The subroutine creates an array of arrays from the
# information read from the file, which each inner row holding one row of the
# histogram.
sub read_histogram_file_for_desired_density {
    my $self = shift;
    my $filename = $self->{_hist_file};
    open FILEIN, $filename
        or die "unable to open file: $!";
    my @hist;
    while (<FILEIN>) {
        next if /^#/;
        next if /^\s*$/;
        chomp;
        my @line;
        if ($filename =~ /.csv$/) {
            @line =  map {$_ =~ s/^\s*|\s*$//; $_} split /,/, $_;
        } else {
            @line = split;
        }
        push @hist, \@line;
    }
    close FILEIN;
    if ($self->{_y_axis_pos_direction} eq "up") {
        my @newhist;
        foreach my $i (0..@hist-1) {
            push @newhist, $hist[scalar(@hist)-$i-1];
        }
        $self->{_input_histogram} = \@newhist; 
    } elsif ($self->{_y_axis_pos_direction} eq "down") {
        $self->{_input_histogram} = \@hist; 
    } else {
        die "Something is wrong with your value for the construction option 'y_xis_pos_direction'";
    }
}


# This subroutine is for reading from a text file the horizontal and the vertical
# limits of the bounding box in which the randomly generated points must reside.  The
# file can either be in the CSV format or the white-space-separated format.  Apart
# from any comment lines that begin with the hash mark, this must must contain
# exactly two lines, the first indicated the x-axis points that define the horizontal
# span of the bounding box and the second indicating the y-axis points that define
# the vertical span of the same.
sub read_file_for_bounding_box {
    my $self = shift;
    my $histref = $self->{_input_histogram};
    my $filename = $self->{_bbox_file};
    open FILEIN, $filename
        or die "unable to open file: $!";
    my @bounding_box;
    while (<FILEIN>) {
        next if /^#/;
        next if /^\s*$/;
        chomp;
        my @line;
        if ($filename =~ /.csv$/) {
            @line =  map {$_ =~ s/^\s*|\s*$//; $_} split /,/, $_;
        } else {
            @line = split;
        }
        die "There must exist exactly two entries in each line of the bounding box file"
            if @line != 2;
        push @bounding_box, \@line;
    }
    die "There must exist only two lines in the bounding box file" if @bounding_box != 2;
    close FILEIN;
    $self->{_x_delta} = ($bounding_box[0][1] - $bounding_box[0][0]) / @{$histref->[0]};
    $self->{_y_delta} = ($bounding_box[1][1] - $bounding_box[1][0]) / @$histref;
    $self->{_bounding_box} = \@bounding_box;
}
    
# This is the heart of the module --- in the sense that this method implements the
# Metropolis-Hastings algorithm for generating the random points.  This algorithm is
# the most popular algorithm today for what is known as the MCMC (Markov Chain Monte
# Carlo) sampling from a desired probability distribution.
sub metropolis_hastings {    
    $|++;
    my $self = shift;
    die "\nyou must first call read_file_for_bounding_box() before you can call\n" .   
        "metropolis_hastings()$!\n" unless $self->{_bounding_box};
    die "\nyou must first call normalize_input_histogram() before you can call\n" .
        "metropolis_hastings()$!\n" unless $self->{_normalized_input_hist};
    die "\nyou must first call set_sigmas_for_proposal_density() before you can call\n" .
        "metropolis_hastings()$!\n" unless $self->{_sigmax_for_proposal_density};
    my $box = $self->{_bounding_box};
    my $N_discard = $self->{_how_many_to_discard};
    my $N_iterations = $self->{_N} + $N_discard;
    my $sample = [$box->[0][0] + ($box->[0][1] - $box->[0][0]) / 2.0,
                  $box->[1][0] + ($box->[1][1] - $box->[1][0]) / 2.0];
    while ($self->desired_density($sample) == 0) {
        $sample = [$self->{_bounding_box}->[0][0] +
             random_uniform() * ($self->{_bounding_box}->[0][1] - $self->{_bounding_box}->[0][0]),
                   $self->{_bounding_box}->[1][0] +
             random_uniform() * ($self->{_bounding_box}->[1][1] - $self->{_bounding_box}->[1][0])]
    }
    print "\nstarting sample: @$sample\n" unless $self->{_command_line_mode};
    if ($self->{_command_line_mode}) {
        print "\nThe Metropolis-Hastings algorithm will be run over 2500 iterations.\n" .
              "Of the 2500 points generated, the first 500 will be discarded.\n" .
              "Each dot shown below stands for 50 iterations of the algorithm.\n\n";
    } else {
        print "\nThe Metropolis-Hastings algorithm will be run for $N_discard more iterations\n" .
              "than the number of points you requested.  The first $N_discard initial points thus\n" .
              "generated will be discarded from the final output.\n\n";
    }
    my @arr;
    foreach my $i (0..$N_iterations-1) {
        unless ($self->{_command_line_mode}) {
            print "\nIteration number: $i  (out of $N_iterations)\n" if $i % ($N_iterations / 10) == 0;
        }
        print ". " if $i % 50 == 0;
        # Get proposal probability q( $y | $x ).
        my ($newsample, $prob) = $self->get_sample_using_proposal( $sample ); 
        my $a1 = $self->desired_density( $newsample ) / $self->desired_density( $sample );
        my $a2 = $self->proposal_density( $sample, $newsample ) / $prob;
        my $a = $a1 * $a2;
        my $u = random_uniform();
        if ( $a >= 1 ) {
            $sample = $newsample;
            push @arr, $sample;
        } elsif ($u < $a) {
            $sample = $newsample;
            push @arr, $sample;
        } else {
            push @arr, $sample;
        }
    }
    print "\nTotal number of iterations run: $N_iterations\n\n" unless $self->{_command_line_mode};
    $self->{_generated_points} = \@arr;
}

# From the standpoint of matching the input histogram, the quality of the random
# points generated by the Metropolis-Hastings algorithm is affected by what sort of a
# probability distribution is used for the proposal density function.  This module
# uses a bivariate Gaussian density function for this purpose whose widths along x
# and y are controlled by constructor parameter "proposal_density_width" that
# defaults to 0.1.  The function here sets the values for the sigmax and sigmay
# parameters of this bivariate density.
sub set_sigmas_for_proposal_density {
    my $self = shift;
    die "\nyou must call read_file_for_bounding_box() before you can call\n" .   
        "set_sigmas_for_proposal_density()$!\n" unless $self->{_bounding_box};
    my $param = $self->{_proposal_density_width};
    my $box = $self->{_bounding_box};
    $self->{_sigmax_for_proposal_density} = ($box->[0][1] - $box->[0][0]) * $param;
    $self->{_sigmay_for_proposal_density} = ($box->[1][1] - $box->[1][0]) * $param;
}

# This function is called by metropolis_hastings() for generating the next point in a
# random walk in the 2D plane:
sub get_sample_using_proposal {
    my $self = shift;
    my $x = shift;
    my $mean = $x;      # for proposal_prob($y|$x)  =  norm($x, $sigma ** 2) 
    my $sigmax = $self->{_sigmax_for_proposal_density};
    my $sigmay = $self->{_sigmay_for_proposal_density};
    my @SIGMA = ( [$sigmax**2, 0], [0, $sigmay**2] );
    my $sample = Math::Random::random_multivariate_normal( 1, @$mean, @SIGMA );
    my $gaussian_exponent = - 0.5 * ( (($sample->[0] - $mean->[0])**2 / $sigmax**2 ) + 
                                (($sample->[1] - $mean->[1])**2 / $sigmay**2 ) ) ;
    my $prob = ( 1.0 / (2 * PI * $sigmax * $sigmay ) ) * euler( $gaussian_exponent );
    return ($sample, $prob);
}            

# This function returns the desired density at the candidate point produced by the by
# proposal density function.  The desired density is calculated by applying bilinear
# interpolation to the bin counts to the four nearest four points in the normalized
# version of the input histogram.
sub desired_density {
    my $self = shift;
    my $sample = shift;
    my $histref = $self->{_normalized_input_hist};
    my $bbsize = $self->{_bounding_box};
    my $horiz_delta = $self->{_x_delta};
    my $vert_delta = $self->{_y_delta};
    print "horiz_delta: $horiz_delta    vert_delta: $vert_delta\n" if $self->{_debug};
    return 0 if $sample->[0] < $bbsize->[0][0] || $sample->[0] > $bbsize->[0][1] ||
                $sample->[1] < $bbsize->[1][0] || $sample->[1] > $bbsize->[1][1];
    print "horizontal extent: $bbsize->[0][0]  $bbsize->[0][1]\n" if $self->{_debug};
    print "vertical extent: $bbsize->[1][0]  $bbsize->[1][1]\n" if $self->{_debug};
    my $bin_horiz = int( ($sample->[0] - $bbsize->[0][0]) / $horiz_delta );
    my $bin_vert = int( ($sample->[1] - $bbsize->[1][0]) / $vert_delta );
    print "bin 2D index: horiz: $bin_horiz   vert: $bin_vert  for sample value @$sample\n"
        if $self->{_debug};
    my $prob00 = $histref->[$bin_vert][$bin_horiz] || 0;
    return $prob00 if (($bin_horiz + 1) >= @{$histref->[0]}) || (($bin_vert + 1) >= @{$histref});
    my $prob01 = $histref->[$bin_vert + 1][$bin_horiz] || 0;
    my $prob10 = $histref->[$bin_vert][$bin_horiz+ 1] || 0;
    my $prob11 = $histref->[$bin_vert + 1][$bin_horiz + 1] || 0;
    print "The four probs: $prob00   $prob01   $prob10   $prob11\n" if $self->{_debug};
    my $horiz_fractional = (($sample->[0] - $bbsize->[0][0]) / $horiz_delta) - $bin_horiz; 
    my $vert_fractional = (($sample->[1] - $bbsize->[1][0]) / $vert_delta) - $bin_vert; 
    print "horiz frac: $horiz_fractional   vert frac: $vert_fractional\n" if $self->{_debug};
    my $interpolated_prob = $prob00 * (1 - $horiz_fractional) * (1 - $vert_fractional) +
                            $prob10 * $horiz_fractional * (1 - $vert_fractional) +   
                            $prob01 * (1 - $horiz_fractional) * $vert_fractional +   
                            $prob11 * $horiz_fractional * $vert_fractional;   
    print "Interpolated prob: $interpolated_prob\n" if $self->{_debug};
    return $interpolated_prob;
}

sub proposal_density {
    my $self = shift;
    my $sample = shift;
    my $mean = shift;
    my $sigmax = $self->{_sigmax_for_proposal_density};
    my $sigmay = $self->{_sigmay_for_proposal_density};
    my @SIGMA = ( [$sigmax, 0], [0, $sigmay] );
    my $gaussian_exponent = - 0.5 * ( (($sample->[0] - $mean->[0])**2 / $sigmax**2 ) + 
                                (($sample->[1] - $mean->[1])**2 / $sigmay**2 ) ) ;
    my $prob = ( 1.0 / (2 * PI * $sigmax * $sigmay ) ) * euler( $gaussian_exponent );
    return $prob;
}

sub normalize_input_histogram {
    my $self = shift;
    die "\nyou must first call read_histogram_file_for_desired_density() before you can call\n" .   
        "normalize_input_histogram()$!\n" unless $self->{_input_histogram};
    my $histref = deep_copy_AoA( $self->{_input_histogram} );
    my $summation = reduce {$a + $b} map {@$_} @$histref;
    foreach my $i (0..@$histref-1) {
        foreach my $j (0..@{$histref->[0]}-1) {
            $histref->[$i][$j] /=  $summation;
        }
    }
    $self->{_normalized_input_hist} = $histref;
}

# Display a 2D histogram.  Requires one argument which must be a reference to an
# array of arrays, which inner array holding one row of the histogram.
sub display_hist_in_terminal_window {
    my $self = shift;
    die "\nyou must first call read_histogram_file_for_desired_density() before you can call\n" .   
        "display_hist_in_terminal_window()$!\n" unless $self->{_input_histogram};
    my $histref = $self->{_input_histogram};
    foreach my $y (0..@$histref-1) {
        foreach my $x (0..@{$histref->[0]}-1) {
            if ($histref->[$y][$x] < 100) {
                printf "%d ",  $histref->[$y][$x];
            } else {
                printf "%.3e ",  $histref->[$y][$x];
            }
        }
        print "\n";
    }
    print "\n";
}

sub write_generated_points_to_a_file {
    my $self = shift;
    die "\nyou must first call metropolis_hastings() before you can call\n" .   
        "write_generated_points_to_a_file()$!\n" unless $self->{_generated_points};
    my $master_file_basename = basename($self->{_hist_file}, ('.csv', '.dat', '.txt'));
    my $out_file = "random_points_generated_for_$master_file_basename.csv";
    my @samples = @{$self->{_generated_points}};
    my $N_discard = $self->{_how_many_to_discard};
    my @truncated_sample_list = @samples[$N_discard..$#samples-1];
    fisher_yates_shuffle(\@truncated_sample_list);
    if (@truncated_sample_list) {
        open( OUTFILE , ">$out_file") or                         
            die "Cannot open out.txt for write: $!";
        foreach my $sample (@truncated_sample_list) {
            printf OUTFILE "%.6f, %.6f\n", $sample->[0], $sample->[1];
        }
        close OUTFILE;                                                 
    }
    print "\nRandom points written out to $out_file\n" if $self->{_command_line_mode};
}

sub write_generated_points_to_standard_output {
    my $self = shift;
    my @samples = @{$self->{_generated_points}};
    my $N_discard = $self->{_how_many_to_discard};
    my @truncated_sample_list = @samples[$N_discard..$#samples-1];
    fisher_yates_shuffle(\@truncated_sample_list);
    if (@truncated_sample_list) {
        foreach my $sample (@truncated_sample_list) {
            printf STDOUT "%.6f, %.6f\n", $sample->[0], $sample->[1];
        }
    }
}

sub display_output_histogram_in_terminal_window {
    my $self = shift;
    die "\nyou must call make_output_histogram_for_generated_points()() before you can call\n" .   
        "display_output_histogram_in_terminal_window()$!\n" unless $self->{_output_histogram};
    my $output_hist = $self->{_output_histogram};
    foreach my $row (@$output_hist) {
        foreach my $sample (@$row) {
            print "$sample ";
        }
        print "\n";
    }
}

sub make_output_histogram_for_generated_points {
    my $self = shift;
    my @data = @{$self->{_generated_points}};
    my @horizonts = map {$_->[0]} @data;
    my @verts = map {$_->[1]} @data;
    my ($hmin, $hmax) = ($self->{_bounding_box}->[0][0], $self->{_bounding_box}->[0][1]);
    my ($vmin, $vmax) = ($self->{_bounding_box}->[1][0], $self->{_bounding_box}->[1][1]);
    my $aspect_ratio = ($vmax - $vmin) / ($hmax - $hmin);
    my $num_bins_x = $self->{_output_hist_bins_along_x};
    my $num_bins_y = int( $num_bins_x * $aspect_ratio );
    my $hist;
    foreach my $y (0..$num_bins_y-1) {
        foreach my $x (0..$num_bins_x-1) {
            $hist->[$y][$x] = 0.0;
        }
    }
    my $bin_width = ($hmax - $hmin) / $num_bins_x;
    my $bin_height = ($vmax - $vmin) / $num_bins_y;
    foreach my $sample (@data) {
        my $hbin_index = int( ($sample->[0] - $hmin) / $bin_width );
        my $vbin_index = int( ($sample->[1] - $vmin) / $bin_height );
        $hist->[$vbin_index][$hbin_index]++ 
                     if ($hbin_index < $num_bins_x) && ($vbin_index < $num_bins_y);
    }
    $self->{_output_histogram} = $hist;
    $self->{_bin_width_for_output_hist} = $bin_width;
    $self->{_bin_height_for_output_hist} = $bin_height;
}

# Plotting a 3D surface with Gnuplot requires that the input data be provided as a
# sequence of triples in a text file, with each triple in a separate line, and with
# each triple consisting of the x coordinate, followed by the y coordinate, which is
# then following by the height of the surface at that point.  Additionally, and very
# importantly, this file must be separated into blocks, with the blocks separated by
# empty lines.  Each block is for a single x coordinate and all the lines in a single
# block must be sorted with respected to the y coordinated.  The blocks must be
# sorted with respect to the x coordinate.
sub plot_histogram_3d_surface {                                             
    my $self = shift;
    die "\nyou must call make_output_histogram_for_generated_points() before you can call\n" .   
        "plot_histogram_3d_surface()$!\n" unless $self->{_output_histogram};
    my $pause_time = shift;
    my $hist = $self->{_output_histogram};
    my @plot_points = ();
    foreach my $y (0..@$hist-1) {
        foreach my $x (0..@{$hist->[0]}-1) {
            push @plot_points, [$x, $y, $hist->[$y][$x]];
            push @plot_points, [$x+1, $y, $hist->[$y][$x]];
            push @plot_points, [$x, $y+1, $hist->[$y][$x]];
            push @plot_points, [$x+1, $y+1, $hist->[$y][$x]];
        }
    }
    @plot_points = sort {$a->[0] <=> $b->[0]} @plot_points;
    @plot_points = sort {$a->[1] <=> $b->[1] if $a->[0] == $b->[0]} @plot_points;
    my $master_file_basename = basename($self->{_hist_file}, ('.csv', '.dat', '.txt'));
    my $temp_file = "__temp_$master_file_basename.dat";
    open(OUTFILE , ">$temp_file") or die "Cannot open temporary file: $!";
    my ($first, $oldfirst);
    $oldfirst = $plot_points[0]->[0];
    foreach my $sample (@plot_points) {
        $first = $sample->[0];
        if ($first == $oldfirst) {
            my @out_sample;
            $out_sample[0] =  $self->{_bounding_box}->[0][0] +  $sample->[0] * 
                                                               $self->{_bin_width_for_output_hist};
            $out_sample[1] =  $self->{_bounding_box}->[1][0] +  $sample->[1] * 
                                                              $self->{_bin_height_for_output_hist};
            $out_sample[2] =  $sample->[2];
            print OUTFILE "@out_sample\n";
        } else {
            print OUTFILE "\n";             
        }
        $oldfirst = $first;
    }
    print OUTFILE "\n";             
    close OUTFILE;                                                 
    my $x_left = $self->{_bounding_box}->[0][0];
    my $x_right = $self->{_bounding_box}->[0][1];
    my $y_lower = $self->{_bounding_box}->[1][0];
    my $y_upper = $self->{_bounding_box}->[1][1];
my $argstring = <<"END";
set xrange [$x_left:$x_right]
set yrange [$y_lower:$y_upper]
set pm3d
splot "$temp_file" with pm3d
END
    unless (defined $pause_time) {
        my $hardcopy_name =  "output_histogram_for_$master_file_basename.png";
        my $plot1 = Graphics::GnuplotIF->new();
        $plot1->gnuplot_cmd( 'set terminal png', "set output \"$hardcopy_name\"");    
        $plot1->gnuplot_cmd( $argstring );
        my $plot2 = Graphics::GnuplotIF->new(persist => 1);
       $plot2->gnuplot_cmd( $argstring );
    } else {
        my $plot = Graphics::GnuplotIF->new();
        $plot->gnuplot_cmd( $argstring );
        $plot->gnuplot_pause( $pause_time );
    }
}

sub plot_histogram_lineplot {                                             
    my $self = shift;
    my $pause_time = shift;
    die "\nyou must call make_output_histogram_for_generated_points() before you can call\n" .   
        "plot_histogram_lineplot()$!\n" unless $self->{_output_histogram};
    my $hist = $self->{_output_histogram};
    my @plot_points = ();
    foreach my $y (0..@$hist-1) {
        foreach my $x (0..@{$hist->[0]}-1) {
            push @plot_points, [$x, $y, $hist->[$y][$x]];
            push @plot_points, [$x+1, $y, $hist->[$y][$x]];
            push @plot_points, [$x, $y+1, $hist->[$y][$x]];
            push @plot_points, [$x+1, $y+1, $hist->[$y][$x]];
        }
    }
    @plot_points = sort {$a->[0] <=> $b->[0]} @plot_points;
    @plot_points = sort {$a->[1] <=> $b->[1] if $a->[0] == $b->[0]} @plot_points;
    my $master_file_basename = basename($self->{_hist_file}, ('.csv', '.dat', '.txt'));
    my $temp_file = "__temp_$master_file_basename.dat";
    open(OUTFILE , ">$temp_file") or die "Cannot open temporary file: $!";
    my ($first, $oldfirst);
    $oldfirst = $plot_points[0]->[0];
    foreach my $sample (@plot_points) {
        $first = $sample->[0];
        if ($first == $oldfirst) {
            my @out_sample;
            $out_sample[0] =  $self->{_bounding_box}->[0][0] +  $sample->[0] * 
                                                               $self->{_bin_width_for_output_hist};
            $out_sample[1] =  $self->{_bounding_box}->[1][0] +  $sample->[1] * 
                                                              $self->{_bin_height_for_output_hist};
            $out_sample[2] =  $sample->[2];
            print OUTFILE "@out_sample\n";
        } else {
            print OUTFILE "\n";             
        }
        $oldfirst = $first;
    }
    print OUTFILE "\n";             
    close OUTFILE;                                                 
my $argstring = <<"END";
set hidden3d
splot "$temp_file" with lines
END
    my $plot;
    if (!defined $pause_time) {
        $plot = Graphics::GnuplotIF->new( persist => 1 );
    } else {
        $plot = Graphics::GnuplotIF->new();
    }
#    my $plot = Graphics::GnuplotIF->new(persist => 1);
    $plot->gnuplot_cmd( $argstring );
    $plot->gnuplot_pause( $pause_time ) if defined $pause_time;
}

sub DESTROY {
    my $self = shift;
    my $master_file_basename = basename($self->{_hist_file}, ('.csv', '.dat', '.txt'));
    unlink glob "__temp_$master_file_basename*";
}

sub deep_copy_AoA {
    my $ref_in = shift;
    my $ref_out;
    foreach my $i (0..@{$ref_in}-1) {
        foreach my $j (0..@{$ref_in->[$i]}-1) {
            $ref_out->[$i]->[$j] = $ref_in->[$i]->[$j];
        }
    }
    return $ref_out;
}

# from perl docs:
sub fisher_yates_shuffle {                
    my $arr =  shift;                
    my $i = @$arr;                   
    while (--$i) {                   
        my $j = int rand( $i + 1 );  
        @$arr[$i, $j] = @$arr[$j, $i]; 
    }
}

sub check_for_illegal_params {
    my @params = @_;
    my @legal_params = qw / input_histogram_file
                            bounding_box_file
                            number_of_points
                            how_many_to_discard
                            proposal_density_width
                            y_axis_pos_direction
                            output_hist_bins_along_x
                            command_line_mode
                            debug
                          /;
    my $found_match_flag;
    foreach my $param (@params) {
        foreach my $legal (@legal_params) {
            $found_match_flag = 0;
            if ($param eq $legal) {
                $found_match_flag = 1;
                last;
            }
        }
        last if $found_match_flag == 0;
    }
    return $found_match_flag;
}

1;

=pod

=head1 NAME

Algorithm::RandomPointGenerator -- This module generates a set of random points in a
2D plane according to a user-specified probability distribution that is provided to
the module in the form of a 2D histogram.


=head1 SYNOPSIS

  #  The quickest way to use the module is through the script genRand2D that you'll
  #  find in the examples subdirectory.  You can move this script to any convenient
  #  location in your directory structure.  Call this script as a command-line utility
  #  in the following manner:

  genRand2D  --histfile  your_histogram_file.csv  --bbfile  your_bounding_box_file.csv

  #  where the '--histfile' option supplies the name of the file that contains a 2D
  #  histogram and the option '--bbfile' the name of the file that defines a bounding
  #  box in the XY-plane to which the histogram applies. The module uses the
  #  Metropolis-Hastings algorithm to draw random points from a probability density
  #  function that is approximated by the 2D histogram you supply through the
  #  '--histfile' option. You can also run the command

  genRand2D  --help

  #  for further information regarding these two command-line options.  An invocation
  #  of genRand2D gives you 2000 random points that are deposited in a file whose
  #  name is printed out in the terminal window in which you invoke the genRand2D
  #  command.


  #  The rest of this Synopsis concerns using the module with greater control over
  #  the production and display of random points.  Obviously, the very first thing
  #  you would need to do would be to import the module:

  use Algorithm::RandomPointGenerator;

  #  Next, name the file that contains a 2D histogram for the desired density
  #  function for the generation of random points:

  my $input_histogram_file = "histogram.csv";

  #  Then name the file that defines the bounding box for the random points:

  my $bounding_box_file =  "bounding_box.csv";

  #  Now construct an instance of RandomPointGenerator using a call that, assuming
  #  you wish to set all the constructor options, would look like:

  my $generator = Algorithm::RandomPointGenerator->new(
                            input_histogram_file    => $input_histogram_file,
                            bounding_box_file       => $bounding_box_file,
                            number_of_points        => 2000,
                            how_many_to_discard     => 500,
                            proposal_density_width  => 0.1,
                            y_axis_pos_direction    => 'down', 
                            output_hist_bins_along_x => 40,
  );

  #  The role served by the different constructor options is explained later in this
  #  documentation. After constructing an instance of the module, you would need to
  #  call the following methods for generating the random points and for displaying
  #  their histogram:

  $generator->read_histogram_file_for_desired_density();
  $generator->read_file_for_bounding_box();
  $generator->normalize_input_histogram();
  $generator->set_sigmas_for_proposal_density();
  $generator->metropolis_hastings();
  $generator->write_generated_points_to_a_file();
  $generator->make_output_histogram_for_generated_points();
  $generator->plot_histogram_3d_surface();

  #  As to what is accomplished by each of the methods called above is described
  #  later in this documentation.  Note that since several of the constructor
  #  parameters have defaults, a minimal call to the constructor may look as brief
  #  as:

  my $generator = Algorithm::RandomPointGenerator->new(
                            input_histogram_file    => $input_histogram_file,
                            bounding_box_file       => $bounding_box_file,
  );
  
  #  In this case, the number of points to be generated is set to 2000.  These will
  #  be the points after the first 500 that are discarded to get past the effects of
  #  the starting state of the generator.


=head1 CHANGES

Version 1.01 downshifts the version of Perl that is required for this module.  The
implementation code for the module is unchanged from Version 1.0.


=head1 DESCRIPTION

Several testing protocols for "big data" research projects involving large geographic
areas require a random set of points that are distributed according to a
user-specified probability density function that exists in the form of a 2D
histogram.  This module is an implementation of the Metropolis-Hastings algorithm for
generating such a set of points.

=head1 METHODS

The module provides the following methods:

=over 4

=item B<new():>

A call to C<new()> constructs a new instance of the
C<Algorithm::RandomPointGenerator> class.  If you wanted to set all the constructor
options, this call would look like:

  my $generator = Algorithm::RandomPointGenerator->new(
                            input_histogram_file    => $input_histogram_file,
                            bounding_box_file       => $bounding_box_file,
                            number_of_points        => 2000,
                            how_many_to_discard     => 500,
                            proposal_density_width  => 0.1,
                            y_axis_pos_direction    => 'down', 
                  );

where C<input_histogram_file> is the name of the file that contains a 2D histogram as
an approximation to the desired probability density function for the random points to
be generated.  The data in the histogram file is expected to be in CSV format.  Here
is a display of a very small portion of the contents of such a file for an actual
geographic region:

    0,211407,216387,211410,205621,199122,192870, ........
    0,408221,427716,427716,427716,427716,427716,427716, ......
    0,408221,427716,427716,427716,427716,427716,427716, ......
    ....
    ....
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,165,9282,11967,15143, .....
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,....

The C<bounding_box_file> parameter of the constructor should delineate the portion of
the plane to which the input histogram corresponds.  Here is an example of the
contents of an actual file supplied for this option:

     -71.772016, -70.431923
     -34.254251,  -33.203240

Apart from any comment lines, there must exist exactly two lines in the bounding-box
file, with the first line indicating the left and the right limits of the horizontal
coordinates and the second line indicating the lower and the upper limits of the
vertical coordinates.  (The values shown above are the longitude and the latitude
limits for a region in Chile, in case you are curious.)

=back 

=head2 Constructor Parameters:

=over 8

=item C<input_histogram_file>:

This required parameter supplies the name of the file that contains a 2D histogram as
the desired density function for the random points that the module will generate.
Each line record in this file must correspond to one row of the 2D histogram.  The
left-to-right direction in the file will be considered to be positive direction for
the x-axis.  As for the positive direction for the y-axis, it is common for that to
be from top to bottom when the histogram is written out to a text file as an array of
integers.  It is important to bear in mind this orientation of the histogram in light
of the fact that a bounding box is specified typically with its y-axis going upwards
(whereas the x-axis continues to be positive from left to right).  This inconsistency
between how a 2D histogram is typically stored in a text file and how a bounding box
is likely to be specified means that if the events occur more frequently in the upper
right hand corner of the bounding box, those high counts would show up in the lower
right hand corner of the histogram in a text file (or in a terminal display of the
contents of such a file). B<You can use the constructor option
C<y_axis_pos_direction> to reverse the positive sense of the y direction for the
histogram.  If you set C<y_axis_pos_direction> to the string C<up>, then the
orientation of the y axis in both the histogram and the bounding box will be the
same.>

=item C<bounding_box_file>:

This required parameter supplies the name of the file that contains the bounding box
information.  By bounding box is meant the part of the XY-plane that corresponds to
the histogram supplied through the C<input_histogram_file> option.  Apart from any
comment lines, this file must contain exactly two lines and each line must contain
exactly two numeric entries.  Additionally, the first entry in each of the two lines
must be smaller than the second entry in the same line.  The two entries in the first
line define the lower and the upper bounds on the x-axis and the two entries in the
second line do the same for the y-axis.

=item C<number_of_points>:

This parameter specifies the number of random points that you want the module to
generate.

=item C<how_many_to_discard>:

The Metropolis-Hastings algorithm belongs to a category of algorithms known as
random-walk algorithms. Since the random walk carried out by such algorithms must be
initialized with user input, it is necessary to discard the points produced until the
effects the initial state have died out.  This parameter specifies how many of the
generated points will be discarded.  This parameter is optional in the sense that it
has a default value of 500.

=item C<proposal_density_width>:

Given the current point, the Metropolis-Hastings randomly chooses a candidate for the
next point.  This random selection of a candidate point is carried out using what is
known as the "proposal density".  The module uses a bivariate Gaussian for the
proposal density.  The value supplied through this parameter controls the standard
deviations of the proposal Gaussian in the x and the y directions.  The default value
for this parameter is 0.1.  With that value for the parameter, the standard deviation
of the proposal density along the x direction will be set to 0.1 times the width of
the bounding box, and the standard deviation of the same along the y-direction to 0.1
times the height of the bounding box.

=item C<y_axis_pos_direction>:

See the explanation above for the constructor parameter C<input_histogram_file> for
why you may need to use the C<y_axis_pos_direction> parameter.  The parameter takes
one of two values, C<up> and C<down>.  The usual interpretation of a 2D histogram in
a text file --- with the positive direction of the y-axis pointing downwards ---
corresponds to the case when this parameter takes the default value of C<down>.

=item C<output_hist_bins_along_x>:

This parameter controls the resolution with which the histogram of the generated
random points will be displayed.  The value you supply is for the number of bins
along the x-direction.  The number of bins along the y-direction is set according to
the aspect ratio of the bounding box.

=back  

=over 

=item B<read_histogram_file_for_desired_density():>

    $generator->read_histogram_file_for_desired_density();

This is a required call after the constructor is invoked. As you would expect, this
call reads in the histogram data for the desired probability density function for
random point generation.

=item B<read_file_for_bounding_box():>

    $generator->read_file_for_bounding_box();

This is also a required call.  This call reads in the left and the right limits on
the x-axis and the lower and the upper limits on the y-axis for the portion of the
XY-plane for which the random points are needed.

=item B<normalize_input_histogram():>

    $generator->normalize_input_histogram();

This normalizes the input histogram to turn it into an approximation to the desired
probability density function for the random points.

=item B<set_sigmas_for_proposal_density():>

    $generator->set_sigmas_for_proposal_density();

The Metropolis-Hastings algorithm is a random-walk algorithm that at each point first
creates a candidate for the next point and then makes a probabilistic decision
regarding the acceptance of the candidate point as the next point on the walk.  The
candidate point is drawn from what is known as the proposal density function.  This
module uses a bivariate Gaussian for the proposal density.  You set the width of the
proposal density by calling this method.

=item B<metropolis_hastings():>

This is the workhorse of the module, as you would expect.  As its name implies, it
uses the Metropolis-Hastings random-walk algorithm to generate a set of random points
whose probability distribution corresponds to the input histogram.

=item B<write_generated_points_to_a_file():>

    $generator->write_generated_points_to_a_file();

This method writes the generated points to a disk file whose name is keyed to the
name of the input histogram file. The two coordinates for each generated random point
are written out to a new line in this file.

=item B<make_output_histogram_for_generated_points():>

    $generator->make_output_histogram_for_generated_points();

The name of the method speaks for itself.

=item B<plot_histogram_3d_surface():>

    $generator->plot_histogram_3d_surface();

This method uses a Perl wrapper for Gnuplot, as provided by the module
Graphics::GnuplotIF, for creating a 3D surface plot of the histogram of the random
points generated by the module.

=item B<plot_histogram_lineplot():>

    $generator->plot_histogram_lineplot(); 

This creates a 3D line plot display of the histogram of the generated random points.

=item B<display_output_histogram_in_terminal_window():>

    $generator->display_output_histogram_in_terminal_window();

Useful for debugging purposes, it displays in the terminal window a two dimensional
array of numbers that is the histogram of the random points generated by the module.

=back

=head1 THE C<examples> DIRECTORY

Probably the most useful item in the C<examples> directory is the command-line script
C<genRand2D> that can be called simply with two arguments for generating a set of
random points.  A call to this script looks like

    genRand2D  --histfile  your_histogram_file.csv  --bbfile  your_bounding_box_file.csv

where the C<--histfile> option supplies the name of the file that contains a 2D input
histogram and the C<--bbfile> option the name of the file that defines the bounding
box in the XY-plane.  You can also execute the command line

    genRand2D  --help

for displaying information as to what is required by the two options for the
C<genRand2D> command.  The command-line invocation of C<genRand2D> gives you 2000
random points that are deposited in a file whose name is printed out in the terminal
window in which you execute the command.

To become more familiar with all of the different options you can use with this
module, you should experiment with the script:

    generate_random_points.pl

You can feed it different 2D histograms --- even made-up 2D histograms --- and look
at the histogram of the generated random points to see how well the module is
working.  Keep in mind, though, if your made-up input histogram has disconnected
blobs in it, the random-points that are generated may correspond to just one of the
blobs.  Since the process of random-point generation involves a random walk, the
algorithm may not be able to hop from one blob to another in the input histogram if
they are too far apart.  As to what exactly you'll get by way of the output histogram
would depend on your choice of the width of the proposal density.

The C<examples> directory contains the following histogram and bounding-box files
for you to get started:

    hist1.csv   bb1.csv

    hist2.csv   bb2.csv    

If you run the C<generate_random_points.pl> script with the C<hist1.csv> and
C<bb1.csv> files, the histogram you get for the 2000 random points generated by the
module will look like what you see in the file C<output_histogram_for_hist1.png>.  On
a Linux machine, you can see this histogram with the usual C<display> command from
the ImageMagick library.  And if you run C<generate_random_points.pl> script with the
C<hist2.csv> and C<bb2.csv> files, you'll see an output histogram that should look
like what you see in C<output_histogram_for_hist2.png>.

You should also try invoking the command-line calls:

    genRand2D --histfile hist1.csv --bbfile bb1.csv

    genRand2D --histfile hist2.csv --bbfile bb2.csv


=head1 REQUIRED

This module requires the following three modules:

   List::Util
   Graphics::GnuplotIF
   Math::Big
   Math::Random

=head1 EXPORT

None by design.


=head1 BUGS

Please notify the author if you encounter any bugs.  When sending email, please place
the string 'RandomPointGenerator' in the subject line.

=head1 INSTALLATION

Download the archive from CPAN in any directory of your choice.  Unpack the archive
with a command that on a Linux machine would look like:

    tar zxvf Algorithm-RandomPointGenerator-1.01.tar.gz

This will create an installation directory for you whose name will be
C<Algorithm-RandomPointGenerator-1.01>.  Enter this directory and execute the
following commands for a standard install of the module if you have root privileges:

    perl Makefile.PL
    make
    make test
    sudo make install

if you do not have root privileges, you can carry out a non-standard install the
module in any directory of your choice by:

    perl Makefile.PL prefix=/some/other/directory/
    make
    make test
    make install

With a non-standard install, you may also have to set your PERL5LIB environment
variable so that this module can find the required other modules. How you do that
would depend on what platform you are working on.  In order to install this module in
a Linux machine on which I use tcsh for the shell, I set the PERL5LIB environment
variable by

    setenv PERL5LIB /some/other/directory/lib64/perl5/:/some/other/directory/share/perl5/

If I used bash, I'd need to declare:

    export PERL5LIB=/some/other/directory/lib64/perl5/:/some/other/directory/share/perl5/


=head1 THANKS

I thank Srezic for pointing out that I needed to downshift the required version of Perl
for this module.  Fortunately, I had access to an old machine still running Perl
5.10.1.  The current version is based on my testing the module on that machine.

=head1 AUTHOR

Avinash Kak, kak@purdue.edu

If you send email, please place the string "RandomPointGenerator" in your
subject line to get past my spam filter.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

 Copyright 2014 Avinash Kak

=cut

