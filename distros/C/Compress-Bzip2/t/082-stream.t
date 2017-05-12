# -*- mode: perl -*-

##
## this is the 03stream.t test from Compress::Bzip2 1.03 with no changes
## (except for comments)
##
## - seems to run a lot slower than the 1.03 test, probably because the add
## routine is now perl, not perlxs.
##

# streaming test

use strict;
use Test::More tests => 208;

use Compress::Bzip2 qw(compress_init decompress_init decompress);

# globals

my $Level = 1;
my @AlNum = ('A'..'Z','a'..'z','0'..'9',' ');
my ($In,$Out) = (0,0);
my $Prefix = 0;


# subs

sub try {
  my ($str,$chunk,$inc) = @_;
  $chunk ||= 100;
  $inc   ||= 0;

  my $stream = compress_init();

  # piece it into chunks and feed it to the monster
  my ($size,$pos,$out,$done,$status,$orig) = ($chunk,0,'');
  for(;;) {
    if($pos > length $str) {
      $status = $stream->finish();
      $done   = 1;
    } else {
      my $piece = substr $str,$pos,$size;
      $pos   += $size;
      $size  += $inc;
      $status = $stream->add($piece);
    }
    return 0 if not defined $status;
    $out .= $status;
    last if $done;
  }

  # see if we can get it back
  if($Prefix) {
    $orig = decompress($stream->prefix().$out);
  } else {
    $stream = decompress_init();

    ($size,$pos,$orig,$done) = ($chunk,0,'');
    for(;;) {
      if($pos > length $out) {
        $status = $stream->finish();
        $done   = 1;
      } else {
        my $piece = substr $out,$pos,$size;
        $pos   += $size;
        $size  += $inc;
        $status = $stream->add($piece);
      }
      return 0 if not defined $status;
      $orig .= $status;
      last if $done;
    }
  }

  $In  += length $orig;
  $Out += length $out;
  return $orig eq $str ? 1 : 0;
}


# tests

# some short strings

my $sum;
ok(try(''),'empty string');
pass('undef');
$sum = 0;
$sum += try($_) for @AlNum;
is($sum,scalar(@AlNum),'alphanumerics');
ok(try('FOO'),'FOO');
ok(try('bar'),'bar');
ok(try('          '),'spaces');

# references are supposed to work too

my $str = 'reference test';
$sum = 0;
for(1..5) {
  $str = \$str;
  $sum += try($str);
}
is($sum,5,'reference tests');

# random strings

$sum = 0;
for my $random(1..100) {
  $Level = 9 if 80 == $random;
  my $str = '';
  $str .= $AlNum[rand @AlNum] for 1..rand 100;
  $sum += try($str);
}
is($sum,100,'100 random strings');

# long strings with repetition

($In,$Out) = (0,0);
for my $random(1..100) {
  $Level = 1 if 20 == $random;
  my $str = '';
  $str .= ($AlNum[rand @AlNum] x rand 1000) for 1..100+rand 900;
  ok(try($str),"long string $random");
}
#diag(sprintf "compression ratio %.2f%%",100*$Out/$In);

# binary strings

($In,$Out) = (0,0);
for my $random(1..100) {
  $Level = 9 if 80 == $random;
  my $str = '';
  $str .= chr(rand 256) for 1..1000+rand 9000;
  ok(try($str),"binary string $random");
}
#diag(sprintf "compression ratio %.2f%%",100*$Out/$In);

