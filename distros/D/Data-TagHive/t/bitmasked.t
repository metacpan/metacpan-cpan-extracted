use 5.12.0;
use warnings;

use Test::More;
use Test::Fatal;
use Try::Tiny;

use lib 't/lib';
use Test::TagHive;

use constant {
  DIFFER       => 16,

  VALUE_TO_SET => 8,
  VALUE_EXISTS => 4,
  MORE_TO_SET  => 2,
  MORE_EXISTS  => 1,
};

my %expect = (
  '00000' => 1,
  '00001' => 1,
  '00010' => 1,
  '00011' => 1,

  '00100' => 1,
  '00101' => 1,
  '00110' => 0,
  '00111' => 0,

  '01000' => 1,
  '01001' => 0,
  '01010' => 1,
  '01011' => 0,

  '01100' => 1,
  '01101' => 1,
  '01110' => 1,
  '01111' => 1,

  # DIFFER is only relevant with VALUE_* on
  '11100' => 0,
  '11101' => 0,
  '11110' => 0,
  '11111' => 0,
);

for my $i (0 .. 31) {
  my $both = (VALUE_TO_SET | VALUE_EXISTS);
  next if ($i & DIFFER) and ($i & $both) != $both;

  new_taghive;

  my $key = sprintf '%05b', $i;
  my $should_live = $expect{ $key };

  die "???? $key" unless defined $should_live;

  my $differ = $i & DIFFER;

  my $to_set = 'key';
  my $exists = 'key';

  $to_set .= ':value'                      if $i & VALUE_TO_SET;
  $exists .= $differ ? ':other' : ':value' if $i & VALUE_EXISTS;

  $to_set .= '.more' if $i & MORE_TO_SET;
  $exists .= '.xtra' if $i & MORE_EXISTS;

  my $lived = 1;

  taghive->add_tag($exists);
  try { taghive->add_tag($to_set) } catch { $lived = 0; };

  my $should = $should_live ? 'live' : 'die';
  is($lived, $should_live, "adding <$to_set> to <$exists> should $should");
}

done_testing;
