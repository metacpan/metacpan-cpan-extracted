#!/usr/bin/perl -w
#
# $Id: process_wav.pl,v 1.8 2007/11/11 21:28:09 bob9960 Exp $
#

=pod

=head1 process_wav.pl

=head2 Overview

This script demonstrates use of the XS interface to 
libgramofile (available from http://sourceforge.net/projects/libgramofile)
which is derived from J. A. Bezemer's Gramofile program (available from 
http://www.opensourcepartners.nl/~costar/gramofile/). 

Gramofile can be used to convert large wav files generated 
from e.g. vinyl LPs into a number of constituent wav files 
(i.e. the songs on the LP or cassette).

This program allowed me to record many sides of vinyl, and then run the 
conversion to flac, mp3 and ogg vorbis files in batch-mode.  A scriptable 
program is better than an interactive one when the parameters change little.

This code splits the file, and then filters the signal by applying
some of the filters available from gramofile. These split and processed
wav files are post-processed with sox, which adjusts the volume of the
file to the maximum possible without clipping. The wav files are then
converted to mp3 format by using lame, to ogg format by using oggenc, and
to lossless compressed wav format by flac.

The raw wav files were recorded using the standard curses interface to 
gramofile, or the Gnome Sound Recorder.

sox is available from http://home.sprynet.com/~cbagwell/sox.html
lame is available from www.sulaco.org
oggenc is available from www.xiph.org as part of vorbis-tools
flac is available from http://sourceforge.net/projects/flac/

=head2 Pragmatism

Infrequently (e.g. with live albums) it's difficult to accurately split the
wav files into their constituent tracks. In this case the .tracks files created
by the track splitting process were hand edited (xmms can play wav files, and
it displays times, too. glame gives more fine control over timings). This 
program was then re-run on the wav file with the flag $use_tracksplit 
switched off.

=cut

use strict;

use File::Basename;
use Getopt::Long;
use File::Temp qw/ :mktemp  /;
use Audio::Gramofile;

# switch this off to use hand-edited .tracks file from Gramofile

my $use_tracksplit=1;

# switch this off to use processed wavs

my $use_signproc=1;

# the following determine what we will produce

my $use_sox = 1;
my $make_flac = 1;
my $make_mp3 = 1;
my $make_ogg = 1;

my $infile_regexp = '\.wav$';
my $outfile_prefix = "out";
my $root_regexp = '^(.*)(?:(\d\d)?\.wav)$';
my $track_regexp = '(\d\d)\.wav$';

my $make_use_rms;
my $make_graphs;
my $blocklen;
my $global_silence_factor;
my $local_silence_threshold;
my $min_silence_blocks;
my $min_track_blocks;
my $extra_blocks_start;
my $extra_blocks_end;

my $simple_median_num_samples;
my $double_median_first_num_samples;
my $double_median_second_num_samples;
my $simple_mean_num_samples;
my $rms_filter_num_samples;
my $cmf_median_tick_num_samples;
my $cmf_rms_length;
my $cmf_recursive_median_length;
my $cmf_decimation_factor;
my $cmf_tick_detection_threshold;
my $cmf2_rms_length;
my $cmf2_recursive_median_length;
my $cmf2_decimation_factor;
my $cmf2_tick_fine_threshold;
my $cmf2_tick_detection_threshold;
my $cmf3_rms_length;
my $cmf3_recursive_median_length;
my $cmf3_decimation_factor;
my $cmf3_tick_fine_threshold;
my $cmf3_tick_detection_threshold;
my $cmf3_fft_length;
my $simple_normalize_factor;
my $begin_time;
my $end_time;
my $process_whole_file;
my $framesize;

my @filter_list;
my $getopt_result = GetOptions (
  'make_use_rms=i' => \$make_use_rms,
  'make_graphs=i' => \$make_graphs,
  'blocklen=i' => \$blocklen,
  'global_silence_factor=i' => \$global_silence_factor,
  'local_silence_threshold=i' => \$local_silence_threshold,
  'min_silence_blocks=i' => \$min_silence_blocks,
  'min_track_blocks=i' => \$min_track_blocks,
  'extra_blocks_start=i' => \$extra_blocks_start,
  'extra_blocks_end=i' => \$extra_blocks_end,
  'filter=s@' => \@filter_list,
  'simple_median_num_samples=i' => \$simple_median_num_samples,
  'double_median_first_num_samples=i' => \$double_median_first_num_samples,
  'double_median_second_num_samples=i' => \$double_median_second_num_samples,
  'simple_mean_num_samples=i' => \$simple_mean_num_samples,
  'rms_filter_num_samples=i' => \$rms_filter_num_samples,
  'cmf_median_tick_num_samples=i' => \$cmf_median_tick_num_samples,
  'cmf_rms_length=i' => \$cmf_rms_length,
  'cmf_recursive_median_length=i' => \$cmf_recursive_median_length,
  'cmf_decimation_factor=i' => \$cmf_decimation_factor,
  'cmf_tick_detection_threshold=i' => \$cmf_tick_detection_threshold,
  'cmf2_rms_length=i' => \$cmf2_rms_length,
  'cmf2_recursive_median_length=i' => \$cmf2_recursive_median_length,
  'cmf2_decimation_factor=i' => \$cmf2_decimation_factor,
  'cmf2_tick_fine_threshold=i' => \$cmf2_tick_fine_threshold,
  'cmf2_tick_detection_threshold=i' => \$cmf2_tick_detection_threshold,
  'cmf3_rms_length=i' => \$cmf3_rms_length,
  'cmf3_recursive_median_length=i' => \$cmf3_recursive_median_length,
  'cmf3_decimation_factor=i' => \$cmf3_decimation_factor,
  'cmf3_tick_fine_threshold=i' => \$cmf3_tick_fine_threshold,
  'cmf3_tick_detection_threshold=i' => \$cmf3_tick_detection_threshold,
  'cmf3_fft_length=i' => \$cmf3_fft_length,
  'simple_normalize_factor=i' => \$simple_normalize_factor,
  'begin_time=s' => \$begin_time,
  'end_time=s' => \$end_time,
  'process_whole_file' => \$process_whole_file,
  'frame_size=i' => \$framesize,
  'use_tracksplit' => \$use_tracksplit,
  'use_signproc' => \$use_signproc,
  'use_sox' => \$use_sox,
  'make_flac' => \$make_flac,
  'make_mp3' => \$make_mp3,
  'make_ogg' => \$make_ogg,
  'infile_regexp=s' => \$infile_regexp,
  'outfile_prefix=s' => \$outfile_prefix,
  'root_regexp=s' => \$root_regexp,
  'track_regexp=s' => \$track_regexp,
);
die "Bad Parameter passed to $0" unless ($getopt_result);

die "process_wav wav_dir output_dir [tmp_dir]" unless (($#ARGV == 1) or ($#ARGV == 2));
die "Need both begin and end time to be specified" 
  if ((defined $begin_time and not defined $end_time) or (not defined $begin_time and defined $end_time));
die "Can't specify begin and end time and process_whole_file" 
  if (defined $process_whole_file and defined $begin_time and defined $end_time);

my $wav_dir = shift @ARGV;
my $output_dir = shift @ARGV;
my $tmp_dir= @ARGV ? shift @ARGV : $wav_dir;

my $silence_blocks=$min_silence_blocks;
my $gramofile = Audio::Gramofile->new or die "Can't make a new Gramofile object, $!";

$gramofile->init_tracksplit("make_use_rms" => $make_use_rms) 
  if (defined $make_use_rms);
$gramofile->init_tracksplit("make_graphs" => $make_graphs) 
  if (defined $make_graphs);
$gramofile->init_tracksplit("blocklen" => $blocklen) if (defined $blocklen);
$gramofile->init_tracksplit("global_silence_factor" => $global_silence_factor) 
  if (defined $global_silence_factor);
$gramofile->init_tracksplit("local_silence_threshold" => $local_silence_threshold) 
  if (defined $local_silence_threshold);
$gramofile->init_tracksplit("min_silence_blocks" => $min_silence_blocks) 
  if (defined $min_silence_blocks);
$gramofile->init_tracksplit("min_track_blocks" => $min_track_blocks) 
  if (defined $min_track_blocks);
$gramofile->init_tracksplit("extra_blocks_start" => $extra_blocks_start) 
  if (defined $extra_blocks_start);
$gramofile->init_tracksplit("extra_blocks_end" => $extra_blocks_end) 
  if (defined $extra_blocks_end);

$gramofile->init_simple_median_filter("num_samples" => $simple_median_num_samples) 
  if (defined $simple_median_num_samples);

$gramofile->init_double_median_filter("first_num_samples" => $double_median_first_num_samples) 
  if (defined $double_median_first_num_samples);
$gramofile->init_double_median_filter("second_num_samples" => $double_median_second_num_samples) 
  if (defined $double_median_second_num_samples);

$gramofile->init_simple_mean_filter("num_samples" => $simple_mean_num_samples) 
  if (defined $simple_mean_num_samples);

$gramofile->init_rms_filter("num_samples" => $rms_filter_num_samples) 
  if (defined $rms_filter_num_samples);

$gramofile->init_cmf_filter("num_samples" => $cmf_median_tick_num_samples) 
  if (defined $cmf_median_tick_num_samples);
$gramofile->init_cmf_filter("rms_length" => $cmf_rms_length) 
  if (defined $cmf_rms_length);
$gramofile->init_cmf_filter("rec_med_len" => $cmf_recursive_median_length) 
  if (defined $cmf_recursive_median_length);
$gramofile->init_cmf_filter("rec_med_dec" => $cmf_decimation_factor) 
  if (defined $cmf_decimation_factor);
$gramofile->init_cmf_filter("tick_threshold" => $cmf_tick_detection_threshold) 
  if (defined $cmf_tick_detection_threshold);

$gramofile->init_cmf2_filter("rms_length" => $cmf2_rms_length) 
  if (defined $cmf2_rms_length);
$gramofile->init_cmf2_filter("rec_med_len" => $cmf2_recursive_median_length) 
  if (defined $cmf2_recursive_median_length);
$gramofile->init_cmf2_filter("rec_med_dec" => $cmf2_decimation_factor) 
  if (defined $cmf2_decimation_factor);
$gramofile->init_cmf2_filter("fine_threshold" => $cmf2_tick_fine_threshold) 
  if (defined $cmf2_tick_fine_threshold);
$gramofile->init_cmf2_filter("tick_threshold" => $cmf2_tick_detection_threshold)
  if (defined $cmf2_tick_detection_threshold);

$gramofile->init_cmf3_filter("rms_length" => $cmf3_rms_length) 
  if (defined $cmf3_rms_length);
$gramofile->init_cmf3_filter("rec_med_len" => $cmf3_recursive_median_length) 
  if (defined $cmf3_recursive_median_length);
$gramofile->init_cmf3_filter("rec_med_dec" => $cmf3_decimation_factor) 
  if (defined $cmf3_decimation_factor);
$gramofile->init_cmf3_filter("fine_threshold" => $cmf3_tick_fine_threshold) 
  if (defined $cmf3_tick_fine_threshold);
$gramofile->init_cmf3_filter("tick_threshold" => $cmf3_tick_detection_threshold)
  if (defined $cmf3_tick_detection_threshold);
$gramofile->init_cmf3_filter("fft_length" => $cmf3_fft_length) 
  if (defined $cmf3_fft_length);

$gramofile->init_simple_normalize_filter("normalize_factor" => $simple_normalize_factor) 
  if (defined $simple_normalize_factor);

$gramofile->use_begin_end_time($begin_time, $end_time) if (defined $begin_time and defined $end_time);
$gramofile->process_whole_file if (defined $process_whole_file);
$gramofile->adjust_frames($framesize) if (defined $framesize);

$gramofile->init_filter_tracks(@filter_list);

opendir(WAVDIR, $wav_dir) || die "can't opendir $wav_dir: $!";

foreach my $file (grep { /$infile_regexp/ } readdir(WAVDIR)) {
  $min_silence_blocks=$silence_blocks;
  print "WAV_DIR is $wav_dir, OUTPUT_DIR is $output_dir, TMP_DIR is $tmp_dir, FILE : $file\n";
  $gramofile->set_input_file($wav_dir . '/' . $file);
  $gramofile->set_output_file($tmp_dir . '/' . $outfile_prefix . $file);
  $gramofile->split_to_tracks if ($use_tracksplit);
  $gramofile->filter_tracks if ($use_signproc);

  opendir(TMPDIR, $tmp_dir) || die "can't opendir $tmp_dir: $!";
  my ($root) = $file =~ /$root_regexp/;
  foreach my $split_wav (grep { /^${outfile_prefix}$root/ } readdir (TMPDIR)) {
    print "split_wav is ",$split_wav,"\n";
    my ($track) = $split_wav =~ /$track_regexp/;
    $track = "01" . $track unless ($track =~ /^\d\d/);
    my $in_file = $tmp_dir . '/' . $split_wav;
    my $out_file = $output_dir . "/" . $root . $track;
    print "INFILE : $in_file, OUTFILE : $out_file, ROOT : $root, STEM : $track\n";

    encode_wav($in_file, $out_file, $track, $use_sox, $make_flac, $make_mp3, $make_ogg);
    unlink $in_file or warn "Can't unlink $in_file, $!";
  }
  closedir TMPDIR;
}
closedir WAVDIR;

sub encode_wav {
  my ($in_file, $out_file, $track, $use_sox, $make_flac, $make_mp3, $make_ogg) = @_;
  print "in_file is $in_file, out_file is $out_file\n";
  print "track is $track\n" if (defined $track);
  my ($tmp_fh, $tmp_file) = mkstemps("/tmp/temp.XXXX", '.wav');

  if ($use_sox) {
    eval { 
      my $soxval = `sox $in_file -e stat -v 2>&1`;
      chomp($soxval);
      print "SOXVAL is $soxval for $in_file\n";
      my @sox_args = ("sox","-v","$soxval",$in_file,$tmp_file);
      system(@sox_args) == 0 or die "system @sox_args failed: $?";
    }; warn $@ if $@;
  }
  if ($make_flac) {
    my $flac_file = $out_file . ".flac";
    eval { 
      my @flac_args = ("flac","--output-name",$flac_file,$tmp_file);
      system(@flac_args) == 0 or die "system @flac_args failed: $?";
    }; warn $@ if $@;
  }
  if ($make_mp3) {
    my $mp3_file = $out_file . ".mp3";
    eval { 
      my @lame_args = ("lame","-h",$tmp_file,$mp3_file);
      system(@lame_args) == 0 or die "system @lame_args failed: $?";
    }; warn $@ if $@;
  }
  if ($make_ogg) {
    my $ogg_file = $out_file . ".ogg";
    eval { 
      my @oggenc_args = ("oggenc","--output=$ogg_file",$tmp_file);
      push @oggenc_args, "-N $track" if ($track);
      system(@oggenc_args) == 0 or die "system @oggenc_args failed: $?"; 
    }; warn $@ if $@;
  }
  unlink $tmp_file or warn "Can't unlink $tmp_file, $!";
}
