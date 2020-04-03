# -*- Mode: CPerl -*-
use Test::More;
use DDC::PP;
use File::Basename;
use lib '.'; ##-- for perl 5.26 (--> '.' is no longer in @INC; did you mean do "./t/parseme.pl"?)
use strict;

my $TEST_DIR = File::Basename::dirname($0);
my $loadpl = do "$TEST_DIR/parseme.pl"
  or die("$0: failed to load parseme.pl: $@");
ok($loadpl,"loaded $TEST_DIR/parseme.pl");

qtestfile(sub { DDC::PP->parse($_[0]) }, "$TEST_DIR/parseme.dat");
done_testing();
