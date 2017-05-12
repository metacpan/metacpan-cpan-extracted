#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';

### generate_random_points.pl

use strict;
use Algorithm::RandomPointGenerator;


my $input_histogram_file = "hist1.csv";
#my $input_histogram_file = "hist2.csv";

my $bounding_box_file =  "bb1.csv";
#my $bounding_box_file =  "bb2.csv";

my $generator = Algorithm::RandomPointGenerator->new(
                            input_histogram_file     => $input_histogram_file,
                            bounding_box_file        => $bounding_box_file,
                            number_of_points         => 2000,
                            how_many_to_discard      => 500,
                            proposal_density_width   => 0.1,
#                            y_axis_pos_direction    => 'up',
                            output_hist_bins_along_x => 40,
                );

$generator->read_histogram_file_for_desired_density();
#$generator->display_hist_in_terminal_window();
$generator->read_file_for_bounding_box();
$generator->normalize_input_histogram();
$generator->set_sigmas_for_proposal_density();
$generator->metropolis_hastings();
$generator->write_generated_points_to_a_file();
$generator->make_output_histogram_for_generated_points();
#$generator->display_output_histogram_in_terminal_window();
$generator->plot_histogram_3d_surface();

