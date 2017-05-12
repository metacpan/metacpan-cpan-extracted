# -*- Mode: CPerl -*-
use Test::More;
use DDC::PP;
use File::Basename;

my $TEST_DIR = File::Basename::dirname($0);
my $loadpl = do "$TEST_DIR/parseme.pl"
  or die("$0: failed to load parseme.pl: $@");
ok($loadpl,"loaded parseme.pl");

qtestfile(sub { DDC::PP->parse($_[0]) }, "$TEST_DIR/parseme.dat");
done_testing();
