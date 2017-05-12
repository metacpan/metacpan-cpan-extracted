#!perl

# vim: ft=perl

use File::Basename;
use Test::More qw(no_plan);

BEGIN {
  use_ok('Audio::Cuefile::Parser');
}

-d 'cue' or exit;

foreach my $cuefile (glob "cue/*cue") {
  my $cue = eval { Audio::Cuefile::Parser->new($cuefile) };

  isa_ok($cue, 'Audio::Cuefile::Parser', basename($cuefile));

  my @tracks = $cue->tracks;

  chomp(my $grepped_amount = `grep -c TRACK "$cuefile"`);
  is($grepped_amount, scalar @tracks, 'amount of tracks');
}
