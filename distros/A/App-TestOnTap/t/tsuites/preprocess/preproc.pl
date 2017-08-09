use strict;
use warnings;

my $now = $ARGV[0];
$ENV{"TESTONTAP_PREPROCESS_TEST_$now"} = 1;
print "# BEGIN ENV\n";
print "$_=$ENV{$_}\n" foreach (keys(%ENV));
print "# END ENV\n";

print "# BEGIN ARGV\n";
print "$_\n" foreach (@ARGV);
print $now+1,"\n";
print "# END ARGV\n";
