#!/usr/bin/perl -wT
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 34;

use Audio::Gramofile;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $gramofile = Audio::Gramofile->new;         # create an object
ok( defined $gramofile,              'new() returned something' );
ok( $gramofile->isa('Audio::Gramofile'),   "and it's the right class" ); 
is( $gramofile->{rms}->{num_samples}, 3, "initialises some variable correctly" );
ok( $gramofile->set_input_file("input.wav"), "set_input_file runs" );
is( $gramofile->{input_file}, "input.wav", "set_input_file sets the correct value" );
is( $gramofile->{tracksplit}->{blocklen}, 4410, "tracklen variable set correctly" );
is( $gramofile->{tracksplit}->{make_use_rms}, 1, "tracklen variable set correctly" );
$gramofile->init_tracksplit(make_use_rms => 0);
is( $gramofile->{tracksplit}->{make_use_rms}, 0, "tracklen variable set correctly" );
$gramofile->init_tracksplit("blocklen" => 1066);
is( $gramofile->{tracksplit}->{blocklen}, 1066, "init_tracksplit initialises some variable correctly" );
is( $gramofile->{tracksplit}->{global_silence_factor}, 150, "initialise variable unchanged correctly" );
ok( $gramofile->init_filter_tracks("simple_mean_filter","rms_filter"), "init_filter_tracks runs correctly" );
is( $gramofile->{filter_num}, 2, "init_filter_tracks sets the filter_num to the correct value" );
ok( $gramofile->set_output_file("output.wav"), "set_output_file runs" );
is( $gramofile->{output_file}, "output.wav", "set_output_file sets the correct value" );
ok( $gramofile->init_simple_median_filter("num_samples" => 7), "init_simple_median_filter runs" );
is( $gramofile->{simple_median}->{num_samples}, 7, "initialises some variable correctly" );
$gramofile->init_double_median_filter("first_num_samples" => 5);
is( $gramofile->{double_median}->{first_num_samples}, 5, "init_double_median_filter initialises some variable correctly" );
ok ($gramofile->init_simple_mean_filter("num_samples" => 9), "init_simple_mean_filter runs" );
is( $gramofile->{simple_mean}->{num_samples}, 9, "initialises some variable correctly" );
ok ($gramofile->init_rms_filter("num_samples" => 3), "init_rms_filter runs" );
is( $gramofile->{rms}->{num_samples}, 3, "initialises some variable correctly" );
$gramofile->init_cmf_filter("rms_length" => 9);
is( $gramofile->{cmf}->{rms_length}, 9, "init_cmf_filter initialises some variable correctly" );
$gramofile->init_cmf2_filter("rec_med_len" => 11);
is( $gramofile->{cmf2}->{rec_med_len}, 11, "init_cmf2_filter initialises some variable correctly" );
ok ($gramofile->init_cmf3_filter("fft_length" => 7), "init_cmf3_filter runs" );
is( $gramofile->{cmf3}->{fft_length}, 7, "initialises some variable correctly" );
ok ($gramofile->init_simple_normalize_filter("normalize_factor" => 25), "init_normalize_filter runs" );
is( $gramofile->{simple_normalize}->{normalize_factor}, 25, "initialises some variable correctly" );
ok( $gramofile->init_double_median_filter(first_num_samples => 7, second_num_samples => 9), "init_double_median_filter runs" );
is( $gramofile->{double_median}->{first_num_samples}, 7, "initialises some variable correctly" );
is( $gramofile->{double_median}->{second_num_samples}, 9, "initialises some variable correctly" );
ok( $gramofile->init_double_median_filter(second_num_samples =>  5), "init_double_median_filter runs" );
is( $gramofile->{double_median}->{second_num_samples}, 5, "initialises some variable correctly" );
is( $gramofile->{double_median}->{first_num_samples}, 7, "initialises some variable correctly" );
