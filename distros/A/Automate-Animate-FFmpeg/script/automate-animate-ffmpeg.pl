#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.13';

use Getopt::Long;
use Text::ParseWords;
use Encode;
use Automate::Animate::FFmpeg;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

my $constructor_params = {
	'input-images' => undef,
	'input-pattern' => undef,
	'output-filename' => undef,
	'verbosity' => 0,
	'ffmpeg-extra-params' => undef,
	'frame-duration' => 0,
};

my @inimages_from_file;

sub enc { Encode::decode_utf8($_[0]) }

my $waiting_for_second_arg = undef;
if( ! Getopt::Long::GetOptions(
	'input-image|i=s' => sub { 
		if( ! defined $constructor_params->{'input-images'} ){ $constructor_params->{'input-images'} = [ $_[1] ] }
		else { push @{ $constructor_params->{'input-images'} },enc($_[1]) }
	},
	# this requires both a pattern and a search-dir
	'input-pattern|p=s{1,2}' => sub {
		# when we have an option with 2+ args, it comes here twice
		# once with 1st arg, second time with 2nd arg, etc.
		my ($k, $v);
		if( defined $waiting_for_second_arg ){
			$k = $waiting_for_second_arg;
			$v =enc($_[1]);
		} else { $k =enc($_[1]); $v = undef }
		if( ! defined $constructor_params->{$_[0]} ){
			$constructor_params->{$_[0]} = [ $k  ]
		} else {
			push @{ $constructor_params->{$_[0]} }, $v
		}
		$waiting_for_second_arg = defined($waiting_for_second_arg) ? undef : $k;
	},
	'input-images-from-file|f=s' => sub { push @inimages_from_file,enc($_[1]) },
	'output-filename|o=s' => sub { $constructor_params->{$_[0]} =enc($_[1]) },
	'frame-duration|f=s' => sub { $constructor_params->{$_[0]} = $_[1] },
	# we pass extra params to ffmpeg, not as a string but as an array of options.
	'ffmpeg-extra-params|X=s' => sub { $constructor_params->{$_[0]} =enc($_[1]) },
	'verbosity|V=i' => sub { $constructor_params->{$_[0]} = $_[1] },
	'help|h|?' => sub { print STDOUT usage($0)."\n"; exit(0); },
) ){ print STDERR usage($0) . "\n\n$0 : error, something wrong with command line parameters.\n"; exit(1) }

my $verbos = $constructor_params->{'verbosity'};

if( $verbos > 0 ){ print STDOUT perl2dump($constructor_params)."$0 : instantiating with above parameters ...\n" }
my $aaFF = Automate::Animate::FFmpeg->new($constructor_params);
if( ! defined $aaFF ){ print STDERR perl2dump($constructor_params)."\n$0 : error, failed to instantiate ".'Automate::Animate::FFmpeg'." with above parameters.\n"; exit(1) }

for my $af (@inimages_from_file){
	if( ! $aaFF->input_file_with_images($af) ){ print STDERR "$0 : error, failed to import images from a list contained in file '$af'.\n"; exit(1); }
}

if( $verbos > 0 ){ print STDOUT "$0 : creating the animation ...\n" }

my $ret = $aaFF->make_animation();
if( $ret != 1 ){ print STDERR "$0 : error, failed to create the animation.\n"; exit(1) }

print STDOUT "$0 : done, success, output file of animation is at '".$aaFF->output_filename()."'.\n";

sub usage {
	return "Usage: ".$_[0]." : <options>\n".
	"Options:\n".
	"--input-image I [--input-image I2 ...] : specify the full path of an image to be added to the animation. Multiple images are expected.\n".
	"  OR\n".
	"--input-images-from-file F [--input-images-from-file F2 ...] : specify a file which contains a list of input images to be animated, each on its own line. Multiple images are expected.\n".
	"  OR\n".
	"--input-pattern P [D] : specify a pattern and optional search dir to select the files from disk. This pattern must be accepted by File::Find::Rule::name(). If search dir is not specified, the current working dir will be used.\n".

	"--output-filename O : the filename of the output animation.\n".
	"[--frame-duration SECONDS : specify the duration of each frame=input image in (fractional) seconds.]\n".
	"[--verbosity N : specify verbosity. Zero being the mute. Default is ".$constructor_params->{'verbosity'}.".]\n".
	"\nThis script will turn a sequence of input images into an animation (mp4) using the excellent, open source program FFmpeg which you must have installed in your system.\n\nProgram by Andreas Hadjiprocopis (bliako\@cpan.org, 2023)\n\n"
}
