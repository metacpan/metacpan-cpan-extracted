package Audio::FindChunks;

use 5.00503;
use strict;

use Data::Flow qw(0.09);

BEGIN {
  require DynaLoader;
  use vars qw($VERSION @ISA);

  @ISA = qw(DynaLoader);

  $VERSION = '2.03';

  bootstrap Audio::FindChunks $VERSION;
  my $do_dbg	   = !!$ENV{FIND_CHUNKS_DEBUG};	# Convert to logical
  eval "sub do_dbg () {$do_dbg}";
}

die "Version 1.00 of Data::Flow is defective.  Upgrade!" if $Data::Flow::VERSION eq '1.00';

# Preloaded methods go here.

sub default ($$$) {my ($o, $k, $v) = @_; $o->{$k} = $v unless defined $o->{$k}}

my $le_short_size  = length pack 'v', 0;
my $short_size	   = length pack 's', 0;
my $int_size	   = length pack 'i', 0;
my $long_post	   = ($] >= 5.006 ? '!' : '');
my $long	   = "l$long_post";
my $long_size	   = length pack $long, 0;
my $double_size    = length pack 'd', 0;
my $pointer_size   = length pack 'p', 0;
my $pointer_unpack = (($pointer_size == $int_size) ? 'I' : "L$long_post");
my $long_min	   = unpack $long, pack $long, -1e100;
my $long_max	   = -$long_min-1;
my $do_dbg	   = $ENV{FIND_CHUNKS_DEBUG};

sub le_short_sample_multichannel ($$$$$$) {
  my ($totstride, $stride, $channels, $out, $chunksize) =
    (shift,shift,shift,shift,shift);
  my $size = length $_[0];
  my $bufaddr = unpack $pointer_unpack, pack 'p', $_[0];
  die "Size of buffer not multiple of total stride" if $size % $totstride;
  # Do in multiples of 7K (to falicitate lcd 8K Level I cache)
  $chunksize = $totstride * int((7*(1<<10))/$totstride) unless defined $chunksize;
  my $processed = 0;
  while ($size > 0) {
    $chunksize = $size if $chunksize > $size;
    $size -= $chunksize;
    my $samples = $chunksize / $totstride;
    $processed += $samples;
    for my $c (0..$channels-1) {
      warn sprintf "Ch %d: Samples %d %d %d %d ..., totstride %d, %d samples\n", 
	$c, unpack('s4', unpack 'P8', pack $pointer_unpack, $bufaddr + $stride * $c), $totstride, $samples
	  if do_dbg();
#  void le_short_sample_stats(char *buf, int stride, long samples, array_stats_t *stat)
      le_short_sample_stats($bufaddr + $stride * $c, $totstride, $samples,
			    $out->[$c]);
      warn sprintf "  => %d\n", unpack 'd', $out->[$c] if do_dbg();
    }
    $bufaddr += $chunksize;
  }
  return $processed;
}

sub rnd ($) {sprintf '%.0f', shift}

my $wav_header = <<EOH;
  a4	# header: 'RIFF'
  V	# size: Size of what follows
  a4	# type: 'WAVE'

  a4	# type1: 'fmt ' subchunk
  V	# size1: Size of the rest of subchunk
  v	# format: 1 for pcm
  v	# channels: 2 stereo 1 mono
  V	# frequency
  V	# bytes_per_sec
  v	# bytes_per_sample
  v	# bits_per_sample_channel

  a4	# type2: 'data' subchunk
  V	# sizedata: Size of the rest of subchunk
EOH

my @wav_fields = ($wav_header =~ /^\s*\w+\s*#\s*(\w+)/mg);

$wav_header =~ s/#.*//g;		# For v5.005

my $header_size = length pack $wav_header, (0) x 20;
sub MY_INF () {1e200}

sub wav_eat_header ($) {
  my $fh = shift;
  my $in;
  my $read = sysread $fh, $in, $header_size or die "can't read the header";
  return {buf => $in} unless $read == $header_size;
  my %vals;
  @vals{@wav_fields} = unpack $wav_header, $in or return {buf => $in};
  return {buf => $in} unless $vals{header} eq 'RIFF';
  die "Unexpected RIFF format"
    unless $vals{type} eq 'WAVE' and $vals{type1} eq 'fmt '
      and $vals{size1} == 0x10 and $vals{format} == 1
	and $vals{bits_per_sample_channel} == 16 and $vals{format} == 1
	  and $vals{type2} eq 'data';
  $vals{buf} = $in;
  return \%vals;
}

sub SOUND () {2}		# Constants... Rarely promoted or demoted
sub SIGNAL () {1}		# May be promoted or demoted
sub NOISE () {0}		# Likewise
sub SILENCE () {-1}		# Rarely promoted or demoted

sub merge_blocks ($) {		# array ref: 0: type, 1: start, 2: len
  my $blocks = shift;
  my $c = 0;
  my @new;
  for my $b (@$blocks) {
    push(@new, [@$b]), next if not @new or $b->[0] != $new[-1][0];
    $new[-1][2] += $b->[2];
  }
  \@new
}

my %defaults = (
  # For getting PCM flow (and if averaging data is read from cache)
    frequency => 44100,
    bytes_per_sample => 4,
    channels => 2,
    sizedata => MY_INF,
    out_fh => \*STDOUT,
    preprocess => {mp3 => [[qw(lame --silent --decode)], [], ['-']]}, # Second contains extra args to read stdin
  # For getting RMS info
    sec_per_chunk => 0.1,
  # RMS cache
    rms_extension => '.rms',
  # For threshold calculation
    threshold_in_sorted_min_rel => 0,
    threshold_in_sorted_min_sec => 1,
    threshold_in_sorted_max_rel => 0.5,
    threshold_in_sorted_max_sec => 0,
    threshold_ratio => 0.15,
    threshold_factor_min => 1,
    threshold_factor_max => 1,
  # Chunkification: smoothification
    above_thres_window => 11,
    above_thres_window_rel => 0.25,
  # Chunkification
    max_tracks => 9999,
    min_signal_sec => 5,
    min_silence_sec => 2,
    ignore_signal_sec => 1,
  # Final enlargement
    local_level_ignore_pre_sec => 0.3,
    local_level_ignore_post_sec => 0.3,
    local_level_ignore_pre_rel => 0.02,
    local_level_ignore_post_rel => 0.02,
    local_threshold_factor => 1.05,
    extend_track_end_sec => 0.5,
    extend_track_begin_sec => 0.3,
    min_boundary_silence_sec => 0.2,
  );

my %mirror_from = (	# May be set separately, otherwise are synonims
    min_actual_silence_sec => 'min_silence_sec',
    min_start_silence_sec => 'min_boundary_silence_sec',
    min_end_silence_sec => 'min_boundary_silence_sec',
    cache_rms_write => 'cache_rms',
    cache_rms_read => 'cache_rms',
    min_silence_chunks_merge => 'min_silence_chunks',
  );

my %chunk_times =
  map {	(my $n = $_) =~ s/_sec/_chunks/;
	($n => {'filter'
		=> [sub {rnd(shift()/shift)}, $_, 'sec_per_chunk']}) }
    grep /_sec$/, keys %defaults, keys %mirror_from;

my @recognized =	# these default to undef, but accessing them is not fatal
  qw(filename stem_strip_extension filter raw_pcm rms_filename close_fh
     override_header_info cache_rms subchunk_size skip_medians);

my %filters = (
 # For getting RMS info
  filestem => [sub { my $f = shift;
		     return 'filehandle' unless defined $f;
		     $f =~ s/\.(\w+)$// if shift;
		     $f }, 'filename', 'stem_strip_extension'],
  input_type => [sub {	return unless defined (my $f = shift);
			return unless $f =~ /\.(\w+)$/;
			my $h = shift;
			return lc $1 if not $h->{$1} and $h->{lc $1};
			$1 }, 'filename', 'preprocess'],
  preprocess_a => [sub {return unless defined $_[0];
			$_[1]->{$_[0]} }, 'input_type', 'preprocess'],
  preprocess_input => [sub { my ($cmd, $f) = @_; return unless $cmd;
			     return [@{$cmd->[0]}, $f, @{$cmd->[2]}]
				if defined $f;
			     return [@{$cmd->[0]}, @{$cmd->[1]}, @{$cmd->[2]}];
		       }, 'preprocess_a', 'filename'],
  fh_bin => [sub { my $fh = shift; binmode $fh; $fh }, 'fh'],
  out_fh_bin => [sub {	return unless shift;
			my $fh = shift; binmode $fh; $fh
		 }, 'filter', 'out_fh'],
  rms_filename_default => [sub {shift() . shift}, 'filestem', 'rms_extension'],
  read_from_rms_file => [sub {	return if shift; # Need output stream, not only RMS
				shift or defined shift
			 }, 'filter', 'cache_rms_read', 'rms_filename'],
  write_to_rms_file => [sub {shift or defined shift},
			'cache_rms_write', 'rms_filename'],
  rms_filename_actual => [sub {my $f = shift; return $f if defined $f; shift},
			  'rms_filename', 'rms_filename_default'],
  samples_per_chunk => [sub {rnd(shift()*shift)}, 'sec_per_chunk', 'frequency'],
  bytes_per_chunk   => [sub {shift()*shift}, 'samples_per_chunk', 'bytes_per_sample'],
  rms_data_arr_f => [sub {return unless shift;
			  local *RMS; open RMS, '< ' . shift or return;	# No file is OK
			  binmode *RMS;
			  my $c = -s \*RMS;
			  my @in;
			  26 == sysread RMS, $in[0], 26 or die "Short read on RMS";
			  $in[0] =~ /^GramoFile Binary RMS Data\n/i
			      or die "Unknown format of RMS file";
			  $c - 26 == sysread RMS, $in[0], $c - 26 or die "Short read on RMS";
			  push @in, unpack "${long}2", substr $in[0], 0, 2*$long_size;
			  substr($in[0], 0, 2*$long_size) = '';
			  die "Malformed length of RMS file"	# sam/chunk, chunks
			      unless $in[2] * $double_size == length $in[0];
			  my $sam = shift;
			  die "Samples per chunk mismatch: RMSfile => $in[1], expected => $sam"	# sam/chunk, chunks
			      unless $in[1] == $sam;
			  \@in }, 'read_from_rms_file', 'rms_filename_actual',
				  'samples_per_chunk'],
 # For threshold calculation
  medians => [sub { my $av = shift; my @r = $av->[0];	# Allocate the buffer
		    double_median3($av->[0], $r[0], shift) unless shift;
		    \@r }, 'rms_data', 'skip_medians', 'chunks'],
  sorted => [sub { my $av = shift; my @r = $av->[0];	# Allocate the buffer
		   double_sort($av->[0], $r[0], shift);
		   \@r }, 'medians', 'chunks'],
  map(("threshold_in_sorted_$_" =>
	 [sub {	my ($c, $r) = shift; $r = $c*shift() + shift() - 1;
		$r = $c - 1 unless $r < $c - 1;
		$r = 0 unless $r > 0; $r
	 }, 'chunks', "threshold_in_sorted_${_}_rel", "threshold_in_sorted_${_}_chunks"],
       "threshold_$_" =>
	 [sub { shift() *
		sqrt unpack 'd', 
		    substr shift->[0], $double_size * rnd(shift), $double_size
	  }, "threshold_factor_$_", 'sorted', "threshold_in_sorted_$_"]),
      'max', 'min'),
  threshold => [sub { my $min = shift; shift() * (shift()-$min) + $min
		}, 'threshold_min', 'threshold_ratio', 'threshold_max'],
 # Chunkification: smoothification
  above_thres => [sub {	my $c = shift; my @r = 'x' x ($int_size * $c); # Reserve space
			double_find_above(shift->[0], $r[0], $c, shift()**2);
			\@r }, 'chunks', 'rms_data', 'threshold'],
  above_thres_in_window => [sub { my $a = shift; my @r = $a->[0];  # Reserve space
				  int_sum_window($a->[0], $r[0], shift, shift);
			    \@r}, 'above_thres', 'chunks', 'above_thres_window'],
  above_thres_window_abs => [sub {shift()*shift},
			     'above_thres_window_rel', 'above_thres_window'],
  maybe_signal => [sub { my $a = shift; my @r = $a->[0]; # Reserve space
			 int_find_above($a->[0], $r[0], shift, shift); \@r
		   }, 'above_thres_in_window', 'chunks', 'above_thres_window_abs'],
 # Chunkification
  maybe_trk_pk => [sub { my $max = shift; my @r = 'x' x (3*$long_size*$max); # Reserve space
			 my $c = bool_find_runs(shift->[0], $r[0], shift, $max);
			 die "Max count $max of track candidates exceeded"
			    unless $c >= 0;
			 substr($r[0], 3*$long_size*$c) = '';	# Truncate
		         \@r }, 'max_tracks', 'maybe_signal', 'chunks'],
 # Unpack
  b0 => [sub {	my ($c, @b) = -1; my $tracks = shift->[0];
		my $cnt = length($tracks)/(3*$long_size);
		my @bl = unpack $long.(3*$cnt), $tracks;
		while (++$c < $cnt) { # [SIGNAL/NOISE, start, len]
		    push @b, [@bl[3*$c, 3*$c + 1, 3*$c + 2]];
		} return [@b] }, 'maybe_trk_pk'],
 # "Force" long enough blocks
  b1 => [sub {	my @b = map [@$_], @{shift()};	# Deep copy
		my ($min_sign, $min_sil) = (shift, shift);
		for my $t (@b) {
		      $t->[0] = SOUND, next
			if $t->[0] == SIGNAL  and $t->[2] >= $min_sign;
		      $t->[0] = SILENCE, next
			if $t->[0] == NOISE and $t->[2] >= $min_sil;
		}
		# Force silence if it happens at boundary:
		$b[$_]->[0] == NOISE and $b[$_]->[0] = SILENCE
		  for 0, -1;
		\@b }, 'b0', 'min_signal_chunks', 'min_silence_chunks'],
 # Ignore short bursts of signals (may be reversed later)
  b2 => [sub {	my @b = map [@$_], @{shift()};	# Deep copy
		my ($c, $ign_sign) = (0, shift);
		while (++$c < @b - 1) { # XXXX What about those with SILENCE?
		  $b[$c]->[0] = NOISE
		    if $b[$c]->[0] == SIGNAL and $b[$c]->[2] <= $ign_sign
		      and $b[$c-1]->[0] == NOISE and $b[$c+1]->[0] == NOISE
		}		# After ignoring, need to merge similar blocks
		merge_blocks \@b }, 'b1', 'ignore_signal_chunks'],
 # Long enough silence block could appear after b1 ==> b2...
  b3 => [sub {	my @b = map [@$_], @{shift()};	# Deep copy
		my $min_sil_mrg = shift;
		for my $t (@b) {
		  $t->[0] = SILENCE, next
		    if $t->[0] == NOISE and $t->[2] >= $min_sil_mrg;
		}		# Need to merge similar blocks???
		merge_blocks \@b }, 'b2', 'min_silence_chunks_merge'],
 # All undecided are signal unless between two silence intervals
  b4 => [sub {	my @b = map [@$_], @{shift()};	# Deep copy
		my ($left, $c) = (SILENCE, -1);
		while (++$c < @b) {
		  my $this = $b[$c][0];
		  $left = $this, next if $this == SILENCE or $this == SOUND;
		  # Found undecided, force to SOUND unless between two SILENCE
		  $b[$c][0] = SOUND, next if $left == SOUND;
		  # $left is SILENCE, need to check the right one...
		  my ($right, $cr) = (SILENCE, $c);
		  while (++$cr < @b) {
		    my $r = $b[$cr][0];
		    $right = $r, last if $r == SILENCE or $r == SOUND;
		  }
		  $b[$c++][0] = $right while $c < $cr;
		  $left = $right;
		}		# After ignoring, need to merge similar blocks
		merge_blocks \@b }, 'b3'],
 # Final enlargement of signal
  b => [sub {	my @b = map [@$_], @{shift()};	# Deep copy
		my ($ign_pre, $ign_pre_rel, $ign_post, $ign_post_rel) = (shift, shift, shift, shift);
		my ($meds, $thres_factor) = (shift, shift);
		my ($ext_beg, $ext_end) = (shift, shift);
		my ($min_silence, $min_silence_s, $min_silence_e) = (shift, shift, shift);
		my $c = -1;
		for my $b (@b) {
		  ++$c;
		  next unless $b->[0] == SILENCE;
		  my $pre  = rnd($ign_pre  + $ign_pre_rel  * $b->[2]);
		  my $post = rnd($ign_post + $ign_post_rel * $b->[2]);
		  my $ilen = $pre + $post;
		  next unless $b->[2] > $ilen;
		  my $s = $b->[1];
		  my $av = double_sum( $meds->[0], $s + $pre, $b->[2] - $ilen ) / ($b->[2] - $ilen);
		  $av *= $thres_factor*$thres_factor;

		  my $e = $s + $b->[2];
		  if ($c) {		# Not for the "leading gap"
		    while ($s < $e) {
		      my $lev = unpack 'd',
			substr $meds->[0], $s*$double_size, $double_size;
		      last if $lev <= $av;
		      $s++;
		    }
		    my $add = $e - $s;
		    $add = $ext_end if $add > $ext_end;
		    $s += $add;
		    $b[$c-1]->[2] += $s - $b->[1];
		    $b->[2] -= $s - $b->[1];
		    $b->[1] += $s - $b->[1];
		  }
		  if ($c != @b-1) {
		    my $e_ini = $e;
		    while ($s < $e) {
		      my $lev = unpack 'd',
			substr $meds->[0], ($e-1)*$double_size, $double_size;
		      last if $lev <= $av;
		      $e--;
		    }
		    my $add = $e - $s;
		    $add = $ext_beg if $add > $ext_beg;
		    $e -= $add;
		    $b[$c+1]->[2] += $e_ini - $e;
		    $b[$c+1]->[1] -= $e_ini - $e;
		    $b->[2] -= $e_ini - $e;
		  }
		  my $min_sil = ($c == 0 ? $min_silence_s :
				 ($c == $#b ? $min_silence_e : $min_silence));
		  $b->[0] = SOUND if $b->[2] < $min_sil;
		} # After ignoring short silence, need to merge similar blocks
		merge_blocks \@b
	 }, 'b4', 'local_level_ignore_pre_chunks', 'local_level_ignore_pre_rel',
	 'local_level_ignore_post_chunks', 'local_level_ignore_post_rel',
	 'medians', 'local_threshold_factor', 'extend_track_begin_chunks',
	 'extend_track_end_chunks', 'min_actual_silence_chunks',
         'min_start_silence_chunks', 'min_end_silence_chunks'],
  );

my %recipes = (
  map(($_ => {default => $defaults{$_}}), keys %defaults),
  map(($_ => {filter => [sub {shift}, $mirror_from{$_}]}), keys %mirror_from),
  %chunk_times,
  map( ($_ => {default => undef}),
	@recognized),
  map(($_ => {filter => $filters{$_}}), keys %filters),
  map(($_ => {prerequisites => ['rms_data']}), 'chunks', 'min', 'max'),
  fh => {self_filter =>
	 [sub {	my ($self, $cmd) = (shift, shift); local *FH;
		if ($cmd) { $cmd = '"' . join('" "', @$cmd) . '"';
		    open FH, "$cmd |" or die "pipe open($cmd) error: $!";
		} else {
		    my $filename = shift;
		    return \*STDIN unless defined $filename;
		    open FH, "< $filename" or die "open($filename) error: $!";
		}
		$self->set(close_fh => 1) unless $self->already_set('close_fh');
		return *FH }, 'preprocess_input', 'filename']},
  rms_data => { oo_output => sub {
		    my $s = shift;
		    my $d = $s->get('rms_data_arr_f');
		    if (defined $d) {
			$s->set(chunks => $d->[2]);
			return $d;
		    }
		    return read_averages($s);
		}},
  );

sub __s_size() {length pack "d2 ${long}2", 0, 0, 0, 0}

sub read_averages ($) {
  my $self = shift;
  my $fh = $self->get('fh_bin');
  my $vals = {};
  $vals = wav_eat_header($fh) unless $self->get('raw_pcm');
  if ($self->get('override_header_info')) {
    for my $k (keys %$vals) {
      $self->set($k => $vals->{$k}) unless $self->already_set($k)
    }
  } else {
    for my $k (keys %$vals) {
      $self->set($k => $vals->{$k})
    }
  }
  my $out_fh = $self->get('out_fh_bin');
  my $buf = $vals->{buf};
  syswrite $out_fh, $buf or die "Error duping output: $!"
    if $out_fh and $vals->{header};	# in PCM mode we write later
  my $off = ($vals->{header} ? 0 : length $buf);
  my @stats = (pack "d2 ${long}2", 0, 0, $long_max, $long_min) x $self->get('channels');

  my $read = $self->get('bytes_per_chunk') - $off;
  my $rem = $self->get('sizedata');
  $rem = MY_INF if $rem == 0x7fffffff;		# Lame puts this sometimes...
  defined (my $cnt = read $fh, $buf, $read, $off)
    or die "Error reading the first chunk: $!";
  syswrite $out_fh, $buf or die "Error duping output: $!"
    if $out_fh;
  $rem -= $cnt;
  die "short read" unless $rem <= 0 or $rem == MY_INF or $cnt == $read;
  my @d = '';
  my ($c, $b_p_s, $channels, $subchunk, $b_p_c) =
    (0, map $self->get($_), qw(bytes_per_sample channels subchunk_size bytes_per_chunk));
  while (1) {
    my $p = le_short_sample_multichannel($b_p_s, 2, $channels, \@stats,
					 $subchunk, $buf)  or last;
    my $max_level = 0;
    for my $s (@stats) {	# Take maximum per channel
      my $level = unpack 'd', $s;
      $max_level = $level if $max_level < $level;
      substr($s, 0, 2*$double_size) = pack 'd2', 0, 0; # Reset per-chunk sums
    }
    $d[0] .= pack 'd', $max_level / $p;
    $c++;
    #warn "avg = ", $sum_square / $p / @stats;
    last unless $rem;
    defined ($cnt = read $fh, $buf, $b_p_c)
      or die "Error reading: $!";
    $rem -= $cnt;
    die "short read: rem=$rem, cnt=$cnt, b_p_c=$b_p_c" unless $rem <= 0 or $rem == MY_INF or $cnt == $b_p_c;
    syswrite $out_fh, $buf or die "Error duping output: $!"
      if $cnt and $out_fh;
    last unless $cnt;
  }
  close $fh or die "Error closing input: $!" if $self->get('close_fh');
  $self->set(chunks => $c);
  $c = 0;
  my (@min, @max);
  for my $s (@stats) {	# Take maximum per channel
    (undef, undef, my $min, my $max) = unpack "d2 ${long}2", $s;
    $min[$c] = $min;
    $max[$c++] = $max;
  }
  $self->set(min => \@min);
  $self->set(max => \@max);
  if ($self->get('write_to_rms_file')) {
    local *RMS;
    local $\ = '';
    my $f = $self->get('rms_filename_actual');
    open RMS, "> $f"
      or die "Can't open RMS file `$f' for write: $!";
    binmode RMS;
    print RMS "GramoFile Binary RMS Data\n";
    print RMS pack "${long}2", map $self->get($_), qw(samples_per_chunk chunks);
    print RMS $d[0];
    close RMS or die "closing RMS file `$f' for write: $!";
  }
  #print "lev=$_" for map sqrt, unpack 'd*', $opts->{avgs};
  push @d, $self->get('samples_per_chunk'), $c;
  \@d
}

sub format_hms ($) {
  my $t = shift;
  my $h = int($t/3600);
  my $m = int(($t - 3600*$h)/60);
  my $s = $t - 3600*$h - $m*60;
  $s = ($h || $m) ? (sprintf '%04.1f', $s) : sprintf '%3.1f', $s;
  $m = $h ? (sprintf '%02dm', $m) : ( $m ? "${m}m" : '');
  $h = $h ? "${h}h" : '';
  "$h$m$s"
}

my @represent = ('', ':', '>');

sub output_level ($$;$) {
  my ($n, $d, $l) = (shift, shift, shift);
  my $db = 10*log(($l * 2)/(1<<30))/log(10); # Max amplitude sine wave = 0db
  my $l2 = sqrt($l);
  $db = sprintf "%.0f", $db;
  my $s = '#' x (($db+96)/3) . $represent[$db % 3];
  printf "%6d:%11s:%7.1f=%4.0fdB: %s\n", $n, format_hms($n*$d), sqrt($l), $db, $s;
}

sub output_levels ($;$) {
  my ($self, $what) = (shift, shift);
  local $\ = "";
  $what ||= 'rms_data';			# 1-element array with a 'd'-packed elt
  my ($opts,$o) = {};
  for $o ($what, qw(frequency bytes_per_sample channels sec_per_chunk
		    bytes_per_chunk)) {
    $opts->{$o} = $self->get($o);
  }
  for $o (qw(min max)) {	# Not available from RMS cache
    eval { $opts->{$o} = $self->get($o) };
  }
  print <<EOP;
Frequency: $opts->{frequency}.  Stride: $opts->{bytes_per_sample}; $opts->{channels} channels.
Chunk=$opts->{sec_per_chunk}sec=$opts->{bytes_per_chunk}bytes.
EOP
  for my $c (0..$opts->{channels}-1) {
    next unless $opts->{min};
    print "\t" if $c;
    my @l = map $opts->{$_}[$c], 'min', 'max';
    my @db = map 20*log(abs($_)/(1<<15))/log(10), @l;
    printf "ch%d: %.1f .. %.1f (%.0fdB;%.0fdB).", $c, @l, @db;
  }
  print "\n";
  my $n = 0;
  output_level($n++, $opts->{sec_per_chunk}, $_) for unpack 'd*', $opts->{$what}[0];
  $self;
}

sub output_blocks ($;$) {
  my $self = shift;
  my $opts = shift;
  my $type = 'b';
  local $\ = "";
  if ($opts and not ref $opts) {
    $type = $opts;
    $opts = {};
  }
  $opts ||= {};
  my %opts = (format => 'long', %$opts);
  my $blocks = $self->get(shift || $type);
  my $l = $self->get('sec_per_chunk');
  printf "# threshold: %s (in %s .. %s)\n",
    map $self->get($_),	qw(threshold threshold_min threshold_max)
      if $opts{format} eq 'long';
  my ($gap, $c, $b) = (0, 0);
  for $b (@$blocks) {
    $gap = $b->[2] * $l, next if $b->[0] < 0;
    printf("%s\t=%s\t# %s len=%s\n",
	   $b->[1] * $l, ($b->[1] + $b->[2]) * $l, ++$c, $b->[2] * $l), next
	if $opts{format} eq 'short';
    printf "%s\t=%s\t# n=%s duration %s; gap %s (%s .. %s; %s)\n",
      $b->[1] * $l, ($b->[1] + $b->[2]) * $l, ++$c,
      $b->[2] * $l, $gap,
	format_hms($b->[1] * $l), format_hms(($b->[1] + $b->[2]) * $l), format_hms($b->[2] * $l);
  }
}

my $splitter_loaded;

sub split_file ($;$$) {
  my ($self, $opt) = (shift, shift);
  my $blocks = $self->get(shift || 'b');
  my $t = $self->get('input_type');
  die "Only MP3 split supported" unless $t and $t eq 'mp3';
  my $l = $self->get('sec_per_chunk');
  my @req = map [$_->[1] * $l, $_->[2] * $l], grep $_->[0] > 0, @$blocks
    or return;
  require MP3::Splitter;
  die "MP3::Splitter v0.02 required"
    if !$splitter_loaded++ and 0.02 > MP3::Splitter->VERSION;
  MP3::Splitter::mp3split($self->get('filename'), $opt || {}, @req);
  $self;
}

sub new {
  my $class = shift;
  my $s = new Data::Flow \%recipes;
  $s->set(@_);
  bless \$s, $class;
}
sub set ($$$) { ${$_[0]}->set($_[1],$_[2]); $_[0] }
sub get ($$)  { ${$_[0]}->get($_[1]) }

my @exchange = qw(chunks rms_data medians sorted channels min max
		  frequency bytes_per_sample sec_per_chunk bytes_per_chunk);

sub get_rmsinfo ($)  {
  my $i = ${$_[0]};
  map $i->get($_), @exchange;
}

sub set_rmsinfo ($@)  {
  my ($self, %h) = shift;
  @h{@exchange} = @_;
  map $$self->set($_, $h{$_}), @exchange;
  $self
}

1;
__END__

=head1 NAME

Audio::FindChunks - breaks audio files into sound/silence parts.

=head1 SYNOPSIS

  use Audio::FindChunks;

  # Duplicate input to output, caching RMS values to a file (as a side effect)
  Audio::FindChunks->new(rms_filename => 'x.rms', filter => 1)->get('rms_data');

  # Output human-readable info, using RMS cache file 'xxx.rms' if present:
  Audio::FindChunks->new(cache_rms => 1, filename => 'xxx.mp3',
			 stem_strip_extension => 1)->output_blocks();

  # Remove start/end silence (if longer than 0.2sec):
  Audio::FindChunks->new(cache_rms => 1, filename => 'xxx.mp3',
			 min_actual_silence_sec => 1e100)->split_file();

  # Split a multiple-sides tape recording
  Audio::FindChunks->new(filename => 'xxx.mp3', min_actual_silence_sec => 11
			)->split_file({verbose => 1});

  # Output the RMS levels of small interval in human-readable form
  Audio::FindChunks->new(filename => 'xxx.mp3')->output_levels();

=head1 DESCRIPTION

Audio sequence is broken into parts which contain only noise ("gaps"),
and parts with usable signal ("tracks").

The following configuration settings (and defaults) are supported:

  # For getting PCM flow (and if averaging data is read from cache)
    frequency => 44100,		# If 'raw_pcm' or 'override_header_info' only
    bytes_per_sample => 4,	# likewise
    channels => 2,		# likewise
    sizedata => MY_INF,		# likewise (how many bytes of PCM to read)
    out_fh => \*STDOUT,		# mirror WAV/PCM to this FH if 'filter'
  # Process non-WAV data:
    preprocess => {mp3 => [[qw(lame --silent --decode)], [], ['-']]}, # Second contains extra args to read stdin
  # RMS cache (used if 'valid_rms')
    rms_extension => '.rms',	# Appended to the 'filestem'
  # Averaging to RMS info
    sec_per_chunk => 0.1,	# The window for taking mean square
  # thresholds picking from the list of sorted 3-medians of RMS data
    threshold_in_sorted_min_rel => 0,	 # relative position of 'threashold_min' 
    threshold_in_sorted_min_sec => 1,	 # shifted by this amount in the list
    threshold_factor_min => 1,		 # the list elt is multiplied by this
    threshold_in_sorted_max_rel => 0.5,  # likewise
    threshold_in_sorted_max_sec => 0,	 # likewise
    threshold_factor_max => 1,  	 # likewise
    threshold_ratio => 0.15,		 # relative position between min/max
  # Chunkification: smoothification
    above_thres_window => 11,		 # in units of chunks
    above_thres_window_rel => 0.25, 	 # fractions of chunks above threshold
					 # in a window to make chunk signal
  # Splitting into runs of signal/noise
    max_tracks => 9999,			 # fail if more signal/noise runs
    min_signal_sec => 5,		 # such runs of signal are forced
    min_silence_sec => 2,		 # likewise
    ignore_signal_sec => 1,		 # short runs of signal are ignored
    min_silence_chunks_merge (see below) # and long resulting runs of silence
					 # are forced
  # Calculate average signal in an interval "deeply inside" silence runs
    local_level_ignore_pre_sec => 0.3,	 # offset the start of this interval
    local_level_ignore_pre_rel => 0.02,  # additional relative offset
    local_level_ignore_post_sec => 0.3,  # likewise for end of the interval
    local_level_ignore_post_rel => 0.02, # likewise
  # Enlargement of signal runs: attach consequent chunks with signal this much
  # above this average over the neighbour silence run
    local_threshold_factor => 1.05,
  # Final enlargement of runs of signal
    extend_track_end_sec => 0.5,	 # Unconditional enlargement
    extend_track_begin_sec => 0.3,	 # likewise
    min_boundary_silence_sec => 0.2,	 # Ignore short silence at start/end

Note that C<above_thres_window> is the only value specified directly in
units of chunks; the other C<*_sec> may be optionally specified in units
of chunks by setting the corresponding C<*_chunks> value.  Note also that
this window should better be decreased if minimal allowed silence length
parameters are decreased.

These values are mirrored from other values if not explicitly specified:

 min_actual_silence_sec << min_silence_sec		# Ignore short gaps
 min_start_silence_sec  << min_boundary_silence_sec	# Same at start
 min_end_silence_sec    << min_boundary_silence_sec	# Same at end
 min_silence_chunks_merge << min_silence_chunks		# See above

 cache_rms_write <<< cache_rms	  # Boolean: write RMS cache
 cache_rms_read  <<< cache_rms	  # Boolean: read RMS cache (unless 'filter')

The following values default to C<undef>:

    filename			# if undef, read data from STDIN
    stem_strip_extension	# Boolean: 'filestem' has no extension
    filter			# If true, PCM data is mirrored to out_fh
    rms_filename		# Specify cache file explicitly
    raw_pcm			# The input has no WAV header
    override_header_info	# The user specified values override WAV header
    cache_rms			# Use cache file (see *_write, *_read above)
    skip_medians		# Boolean: do not calculate 3-medians
    subchunk_size		# Optimization of calculation of RMS; the
				# best value depends on the processor cache

=head1 METHODS

=over

=item C<new(key1 =E<gt> value1, key2 =E<gt> value2, ....)>

The arguments form a hash of configuration parameters.

=item C<set(key =E<gt> value)>

set a configuration parameter.

=item C<get(key)>

get a configuration parameter or a value which may be calculated basing on
them.

=item C<output_levels([key])>

prints a human-readable display of RMS (or similar) values.  Defaults to
C<rms_data>; additional possible values are C<medians> and C<sorted>.

The format of the output data is similar to

  Frequency: 44100.  Stride: 4; 2 channels.
  Chunk=0.1sec=17640bytes.
  ch0: -9999.0 .. 9999.0 (-10dB;-10dB).	ch1: -9999.0 .. 9999.0 (-10dB;-10dB).
       0:        0.0:   20.7= -61dB: ###########>
       1:        0.1:   20.7= -61dB: ###########>
       2:        0.2:   20.7= -61dB: ###########>
  ...

(with the C<ch0 ETC> line empty if data is read from an RMS file).  Each
chunk gives a line with the chunk number, start (in sec), RMS intensity
(in linear scale and in decibel), and the graphical representation of the
decibel level (each C<#> counts as 3dB, C<:> adds 1dB, and C<E<gt>>
adds 2dB).

=item C<output_blocks([option_hashref], [key])>

prints a human-readable display of obtained audio chunks.  C<key> defaults to
C<b>; additional possible values are C<b0> to C<b4>.  Recognized options key
is C<format>; defaults to C<long>, which results in windy output; the value
C<short> results in shorter output and no preamble.  Preamble lines are all
C<#>-commented; any output line is in the form

  START_SEC =END_SEC # COMMENT

With C<short> format there is no preamble, and (currently) C<COMMENT> is of
the form C<PIECE_NUMBER len=PIECE_DURATION_SEC>.  These formats are
recognized, e.g., by MP3::Split::mp3split_read().

The default format is currently

  # threshold: 1078.46653890971 (in 20.7214163971884 .. 7072.35556648067)
  4.4	=25.8	# n=1 duration 21.4; gap 4.4 (4.4 .. 25.8; 21.4)
  27.7	=67	# n=2 duration 39.3; gap 1.9 (27.7 .. 1m07.0; 39.3)

=item C<split_file([options], [key])>

Splits the file (only MP3 via L<MP3::Splitter> is supported now).  The
meaning of options is the same as for L<MP3::Splitter>.  Defaults to
blocks of type C<b>; additional possible values are C<b0> to C<b4>.

=item @vals = get_rmsinfo(); set_rmsinfo(@vals)

Duplicate RMS info between two different C<Audio::FindChunks> objects.
The exchanged info is the following:

    chunks rms_data medians sorted channels min max
    frequency bytes_per_sample sec_per_chunk bytes_per_chunk

set_rmsinfo() returns the object itself.

=back

=head1 set() and get()

=head2 In and Out

The functionality of the module is modelled on the architecture of
L<Data::Flow>: the two principal methods are C<set(key =E<gt> value)>
and C<get(key)>; the module knows how to calculate keys basing on values of
other keys.

The results of calculation are cached; in particular, if one needs to calculate
some value for different values of a configuration parameter, one should
create many copies of C<Audio::FindChunks> object, as in

  my @info = Audio::FindChunks->new(filename => $f)->get_rmsinfo;
  for my $ratio (0..100) {
    Audio::FindChunks->new(threshold_ratio => $r/100)
	->set_rmsinfo(@info)->print_blocks();
  }

The internally used format of intermediate data is designed for quick shallow
copying even for enourmous audio files.

=head2 Dependencies

The current dependecies for values which are not explicitly set():

  filestem		<<< filename stem_strip_extension
  input_type		<<< filename
  preprocess_a		<<< input_type preprocess
  preprocess_input 	<<< preprocess_a filename
  fh AND close_fh	<<< preprocess_input filename
  fh_bin		<<< fh
  out_fh_bin		<<< filter out_fh
  rms_filename_default	<<< filestem rms_extension
  read_from_rms_file	<<< filter cache_rms_read rms_filename
  write_to_rms_file	<<< cache_rms_write rms_filename
  rms_filename_actual	<<< rms_filename rms_filename_default
  samples_per_chunk	<<< sec_per_chunk frequency
  bytes_per_chunk	<<< samples_per_chunk bytes_per_sample
  rms_data_arr_f	<<< read_from_rms_file rms_filename_actual
				samples_per_chunk
  rms_data AND chunks	<<< rms_data_arr_f OR A LOT OF OTHER PARAMETERS
  medians		<<< rms_data skip_medians chunks
  sorted		<<< medians chunks,
  threshold_in_sorted_* <<< chunks threshold_in_sorted_*_*
  threshold_min/max	<<< threshold_factor_* sorted threshold_in_sorted_min/max
  threshold		<<< threshold_min threshold_ratio threshold_max
  above_thres		<<< chunks rms_data threshold
  above_thres_in_window	<<< above_thres chunks above_thres_window
  above_thres_window_abs<<< above_thres_window_rel above_thres_window
  maybe_signal		<<< above_thres_in_window chunks above_thres_window_abs
  maybe_trk_pk		<<< max_tracks maybe_signal chunks
  b0			<<< maybe_trk_pk
  b1			<<< b0 min_signal_chunks min_silence_chunks
  b2			<<< b1 ignore_signal_chunks
  b3			<<< b2 min_silence_chunks_merge
  b4			<<< b3
  b			<<< b4 local_level_ignore_*
				medians local_threshold_factor
				extend_track_begin_chunks
				extend_track_end_chunks
				min_actual_silence_chunks
				min_start_silence_chunks min_end_silence_chunks

If C<rms_data> is not read from cached source, a lot of other fields may
be also set from the WAV header (unless C<raw_pcm>).

=head3 Formats

Potentially large internally-cached values are stored as array references
to decrease the overhead of shallow copying.

The data which relates to
the initial chunks (of size C<sec_per_chunk>) is stored as length 1 arrays
with packed (either by C<l*> or C<d*>, depending on the semantic) data; this
allows small memory footprint work with huge audio files, and allows
an easy implemenation of most computationally intensive work in C.

The blocks of audio/signal/noise/silence are stored as Perl arrays; each
element is a reference to an array of length 3: type (-1 for silence, 0
for noise, 1 for signal, and 2 for audio), start chunks, duration in chunks.

=head1 ALGORITHM

The algorithm for finding boundaries of parts follows closely the algorithm
used by GramoFile v1.7 (however, I<this> version is I<fully> customizable,
fully documented, and has some significant bugs fixed).  The keywords in the
discussion below refer to customization parameters; keywords of the form
C<E<gt>E<gt>E<gt>key> refer to C<get()>able values set on the step in
question.

=over

=item Smooth the input

This is done in 2 distinct steps:

Break the input into chunks of equal duration (governed by C<sec_per_chunk>);
find the acoustic energy of each channel per chunk (no customization);
energy is the quadratic average of signal level; calculate maximal
energy among channels per chunk (no customization; C<E<gt>E<gt>E<gt>rms_data>).

Trim "extremal" chunks by replacing the energy level of each chunk by
the median of it and its two neighbors (switched off if C<skip_medians>;
C<E<gt>E<gt>E<gt>medians>).

=item Calculate the signal/noise threshold

basing on the distribution (C<E<gt>E<gt>E<gt>sorted>) of smoothed values.
Governed by C<threshold_*> parameters.  C<E<gt>E<gt>E<gt>threshold_min>,
C<E<gt>E<gt>E<gt>threshold_max>, C<E<gt>E<gt>E<gt>threshold>.

=item Smooth it again

Separate into I<signal> and I<noise> chunks basing on the number of
above-threshold chunks in a small window about the given chunk.  Governed by
C<above_thres_window>, C<above_thres_window_rel>.  C<E<gt>E<gt>E<gt>maybe_signal>,
C<E<gt>E<gt>E<gt>b0>.

=item Find certain intervals of sound and silence

Long enough runs of signal chunks are proclaimed carrying sound; likewise
for noise chunks and silence.  Governed by C<max_tracks>, C<min_signal_chunks>,
C<min_silence_chunks>.  C<E<gt>E<gt>E<gt>b1>.

Long enough "unproclaimed" runs of chunks with only short bursts of
signal are proclaimed silence.  Governed by C<ignore_signal_chunks>,
C<E<gt>E<gt>E<gt>b2>; and C<min_silence_chunks_merge>, C<E<gt>E<gt>E<gt>b3>.

=item Merge undecided into sound/silence

A run of chunks (signal or noise) "yet unproclaimed" to be sound or
silence is proclaimed sound if it is adjacent to a run of sound on at
least one side.  The rest of unproclaimed runs are proclaimed silence.
No customization.

Runs of sound/silence are audio/gap candidates (no customization;
C<E<gt>E<gt>E<gt>b4>).

=item Calculate average signal level in each gap candidate

ignoring short intervals near ends of gaps.  Governed by C<local_level_*>.

=item Allow for slow attack/decay or fade in/out

Extend runs of audio: join the consequent runs of chunks of adjacent gaps
where the energy level
remains significantly larger than the average level in this gap.
Additionally, unconditionally extend the tracks by a small amount.
Governed by C<local_threshold_factor>, C<extend_track_end_chunks>,
C<extend_track_begin_chunks>.

=item Long enough gap candidates are gaps

Gaps which became too short are considered audio and are merged into
neighbors.  Governed by C<min_actual_silence_chunks>, C<min_start_silence_chunks>,
C<min_end_silence_chunks>; C<E<gt>E<gt>E<gt>b>.

=back

=head2 Functions implemented in C

  long bool_find_runs(int *input, array_run_t *output, long cnt, long out_cnt)
  void double_find_above(double *input, int *output, long cnt, double threshold)
  void double_median3(double *rmsarray, double *medarray, long total_blocks)
  void double_sort(double *input, double *output, long cnt)
  void int_find_above(int *input, int *output, long cnt, int threshold)
  void int_sum_window(int *input, int *output, long cnt, int window_size)
  void le_short_sample_stats(char *buf, int stride, long samples, array_stats_t *stat)

=head1 SEE ALSO

C<Data::Flow>, C<MP3::Split>

=head1 AUTHOR

Ilya Zakharevich, E<lt>cpan@ilyaz.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
