use strict;
use warnings;
use Test::More;

use Data::Dumper::Compact;

foreach my $example (glob('ex/deep*')) {
  my $contents = do { local (@ARGV, $/) = $example; <> };
  my $data = eval '+'.$contents;
  is(Data::Dumper::Compact->dump($data), $contents);
}

done_testing;
