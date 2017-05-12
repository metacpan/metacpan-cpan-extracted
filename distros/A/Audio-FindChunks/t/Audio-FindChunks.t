#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Audio-FindChunks.t'

# A poor-man indicator of a crash
BEGIN {open CR, '>tst-run' and close CR}	# touch a file
END {unlink 'tst-run'}				# remove it - unless we crash

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 37 };
use Audio::FindChunks;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $pi2 = 2*atan2(0, -1);
sub write_sine ($$$$$) {
  my ($fh, $samples, $freq, $ampl, $phase) = @_;
  while (--$samples >= 0) {
    my $v = sin($phase) * $ampl;
    $phase += $freq * $pi2;
    my $short = pack 'v', unpack 'S', pack 's', $v;
    print $fh $short x 2;
  }
}

sub write_header {
  my @b = qw(
      52 49 46 46  44 D7 A6 01  57 41 56 45  66 6D 74 20
      10 00 00 00  01 00 02 00  44 AC 00 00  10 B1 02 00
      04 00 10 00  64 61 74 61   ); # 20 D7 A6 01
  my $str = join '', map {pack 'H2', $_} @b;
  my ($fh, $len) = (shift, shift);
  print $fh substr($str, 0, 4), pack('V', $len + length($str) + 4), substr($str, 8);
  print $fh pack 'V', $len;			# length
}

my @chunks = ([5,30], [20, 1e4], [0.9, 30], [0.3, 1e4], [0.9, 30], [0.3, 1e4], [0.9, 30], [10.9, 1e4], [0.9, 30], [0.3, 1e4], [0.9, 30], [24.9, 1e4], [3, 30]);	# [len, ampl]
#my @chunks = ([1,30], [2, 1e4], [0.9, 30], [0.3, 1e4], [0.9, 30], [2.9, 1e4], [1, 30]);	# [len, ampl]
my $tot = 0;
map $tot += $_->[0], @chunks;

if ($] >= 5.010) {		# as of v2.02, we are failing on Darwin and ARM
  open my $fh, '>', \my $dbg;
  write_sine($fh, 5, 2000/44100, 30, 3.4);
  close $fh;
  ok length $dbg, 20, '5 samples take 20 bytes';
  (my $h = unpack 'H*', $dbg) =~ s/\B(?=(.{4})+$)/ /sg;
#  ok $h, join(' ', ('0000') x 10), '5 samples';
  ok $h, 'f9ff f9ff f1ff f1ff eaff eaff e6ff e6ff e3ff e3ff', '5 samples';
} else {
  ok 1, 1, 'skip: 5 samples take 20 bytes';
  ok 1, 1, 'skip: 5 samples';
}

unless (-f 'tmp.rms') {
  open OUT, '>tmp.wav' or die;
  binmode OUT;
  write_header(\*OUT, 2 * 2 * 44100 * $tot);
  ok tell(\*OUT), 44, 'header is 44 bytes';
  for my $c (@chunks) {
    write_sine(\*OUT, int(0.5 + 44100 * $c->[0]), 2000/44100, $c->[1], 0);
  }
  close OUT or die;
} else {
  ok 1, 1, 'skip: header is 44 bytes';
}
ok(1,1, 'create a wave or RMS');

my $step;
for $step (1,2) {
  my $h = Audio::FindChunks->new(	stem_strip_extension => 1,
                                  min_silence_sec => 1.5,		# default 2
                                  cache_rms => 1,
                                  filename => 'tmp.wav');
  ok(1,1, 'create an object');
  $h->get('rms_data');
  ok(1,1, 'fetch RMS data');
  my $t = $h->get('threshold');
  ok($t < 1100,1, "threshold $t < 1100");	# in v2.01/Intel:  1078.17744444174 (in 20.7122111714316 .. 7070.48043297351)
  my $fail_t = ($t >= 1100);
  ok($t > 900,1, "threshold $t > 900");

  $h->get('maybe_signal');
  ok(1,1, 'signal and noise separation');

  my $b = $h->get('b');
  ok(1,1, 'blocks');

  sub str { join ' ', map "[@$_]", @{$h->get( shift )} }

  my @ques = map "b$_", 0..4, '';
  my @ans = split /\n/, <<EOT;
[0 0 47] [1 47 206] [0 253 3] [1 256 9] [0 265 3] [1 268 9] [0 277 3] [1 280 115] [0 395 3] [1 398 9] [0 407 3] [1 410 255] [0 665 27]
[-1 0 47] [2 47 206] [0 253 3] [1 256 9] [0 265 3] [1 268 9] [0 277 3] [2 280 115] [0 395 3] [1 398 9] [0 407 3] [2 410 255] [-1 665 27]
[-1 0 47] [2 47 206] [0 253 27] [2 280 115] [0 395 15] [2 410 255] [-1 665 27]
[-1 0 47] [2 47 206] [-1 253 27] [2 280 115] [-1 395 15] [2 410 255] [-1 665 27]
[-1 0 47] [2 47 206] [-1 253 27] [2 280 115] [-1 395 15] [2 410 255] [-1 665 27]
[-1 0 44] [2 44 214] [-1 258 19] [2 277 393] [-1 670 22]
EOT

  for my $q (0..$#ques) {
    ok (str($ques[$q]), $ans[$q], "field $ques[$q]");
  }

  open OUT, ">blocks$step.tmp" or warn;
  my $old = select OUT;

  $h->output_blocks();
  ok(1, 1, 'output_blocks()');

  $h->output_levels();
  ok(1, 1, 'output_levels()');

  #$h->output_levels('medians');
  #ok(1, 1, 'output_levels("medians")');

  select $old;
  close OUT or warn;

  system '( head blocks1.tmp; head -n 60 blocks1.tmp | tail ) 1>&2'
    if $fail_t and $step == 1;		# Fails on ARM with v2.01
}

ok(Audio::FindChunks::_s_size, Audio::FindChunks::__s_size, 'sizes of struct array_stats_t');
ok(Audio::FindChunks::___sh_square(1e4), 1e8, 'assigning square of short to double');

# perl -wle "@r = map int rand 100, 1..25; print qq(@r); @rr = map {(sort {$a<=>$b} @r[$_-1,$_,$_+1])[1]} 1..23; print qq(   @rr)">my_med3
my @in = qw(
 12 4 4 96 49 98 47 78 74 18 36 14 29 28 6  64 59 11 38 35 5  38 74 55 7
);
my @med = qw(
 4  4 4 49 96 49 78 74 74 36 18 29 28 28 28 59 59 38 35 35 35 38 55 55 55
);
ok(Audio::FindChunks::double_median3(pack('d*', @in), my $o = pack('d'.scalar @in), scalar @in), undef,'calc double_median3');
my @o = unpack 'd*', $o;
ok("@o", "@med", 'correct double_median3');


my $del = $ENV{AUDIO_FH_TEST_UNLINK};
defined $del or $del = 1;
$del and -f 'tmp.wav' and (unlink 'tmp.wav' or warn "unlink: $!");
