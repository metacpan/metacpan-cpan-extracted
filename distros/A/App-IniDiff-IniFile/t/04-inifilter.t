use Test::Cmd;
use Test2::Bundle::More;
use Cwd;
use File::Temp;

plan tests => 3;

my $dir = getcwd;

my $test = Test::Cmd->new();

$test->workdir('');

sub removeLineEndings {
  my $line = shift;
  $line =~ tr/\n\r//d;
  return $line;
}

my $resultsDir = $dir.'/t/results';
if (!-d $resultsDir || !-w $resultsDir) {
  # create results directory in t folder, but perms may prevent it
  if (!mkdir $resultsDir || !-w $resultsDir) {
    # in which case use temp directory
    $resultsDir = File::Temp->newdir();
  }
} else {
  # do not remove files here, as future progs use them
  # unlink glob $resultsDir."/*.*"
}
my $archiveDir =  $dir.'/t/archive';
my $dataDir =  $dir.'/t/data';

$test->read(\$archive, $archiveDir.'/result_filter_sample.ini');
$archive = removeLineEndings($archive);

# FAIL: does not find the included file when run here
$test->run(
   prog => 'bin/inifilter',
   interpreter => 'perl',
   args => '-f '.$dataDir.'/sample.ini '.$dataDir.'/filter.ini',
  # verbose => 1,
);
# grab stdout before anything else happens
my $stdoutStr = $test->stdout;
$stdoutStr = removeLineEndings($stdoutStr);
is( $stdoutStr, $archive, 'inifilter: write to stdout' );

$test->run(
  prog => 'bin/inifilter',
  interpreter => 'perl',
  args => '-f '.$dataDir.'/sample.ini -o '.$resultsDir.'/result_filter_sample.ini '.$dataDir.'/filter.ini',
);
$test->read(\$result, $resultsDir.'/result_filter_sample.ini');
$result = removeLineEndings($result);
is( $result, $archive, 'inifilter: write to output file');
is( $? >> 8,       0,       'exit status' );

