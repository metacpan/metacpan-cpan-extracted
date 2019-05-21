use strict;
use warnings;
use Test::More;

use Data::Dumper::Compact;

my $can_j = eval { require JSON::Dumper::Compact; 1 };

DEEP: foreach my $example (glob('ex/deep*')) {
  my $contents = do { local (@ARGV, $/) = $example; <> };
  my $data = eval '+'.$contents;
  is(Data::Dumper::Compact->dump($data), $contents);
  if ($can_j) {
    (my $jfile = $example) =~ s/deep/jdeep/;
    next DEEP unless -e $jfile;
    my $jcont = do { local (@ARGV, $/) = $jfile; <> };
    is(my $res = JSON::Dumper::Compact->dump($data), $jcont);
    is(
      Data::Dumper::Compact->dump(JSON::Dumper::Compact->decode($res)),
      $contents,
    );
  }
}

done_testing;
