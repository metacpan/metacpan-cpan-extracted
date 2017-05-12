use 5.12.0;
use warnings;
use English qw(-no_match_vars);

use FindBin qw($Bin);
use Test::More tests => 2;

my $testDir = "$Bin/../t/";

# Run the build script to create the fatpacked binary
system("$EXECUTABLE_NAME $Bin/../build/build.PL $testDir");

ok(-e "$testDir/cmddirs");

my $expected = `pod2usage $testDir/cmddirs 2>&1`;
my $output = `$testDir/cmddirs -h`;
ok($output =~ /\Q$expected\E/, "Help output contains pod2usage output");

unlink("$Bin/../t/cmddirs");
