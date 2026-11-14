use strict;
use warnings;
use Test::More;
use File::Temp ();

use lib q(t/lib);
use TestDBIO::Child;

# DBIO::Test::Slow lets a developer skip the slow files with DBIO_TEST_FAST,
# and must never do so for a release run or a smoker. Each case runs a marked
# two-line test file in a child perl and reads its TAP.

my $dir  = File::Temp->newdir;
my $file = "$dir/marked.t";
open my $fh, '>', $file or die "$file: $!";
print $fh "use Test::More;\nuse DBIO::Test::Slow;\nok(1, 'marked body ran');\ndone_testing;\n";
close $fh;

sub tap_for {
  my (%env) = @_;
  local %ENV = %ENV;
  delete @ENV{qw(DBIO_TEST_FAST RELEASE_TESTING AUTOMATED_TESTING)};
  @ENV{keys %env} = values %env;
  return TestDBIO::Child::run_perl(script => $file)->{output};
}

like tap_for(), qr/^ok 1 - marked body ran/m, 'without the variable the file runs';

my $fast = tap_for(DBIO_TEST_FAST => 1);
like $fast, qr/^1\.\.0 # SKIP.*DBIO_TEST_FAST/m, 'with DBIO_TEST_FAST the file is skipped';
unlike $fast, qr/marked body ran/, 'and its body does not run';

like tap_for(DBIO_TEST_FAST => 1, AUTOMATED_TESTING => 1), qr/^ok 1 - marked body ran/m,
  'AUTOMATED_TESTING wins over DBIO_TEST_FAST';
like tap_for(DBIO_TEST_FAST => 1, RELEASE_TESTING => 1), qr/^ok 1 - marked body ran/m,
  'RELEASE_TESTING wins over DBIO_TEST_FAST';

done_testing;
