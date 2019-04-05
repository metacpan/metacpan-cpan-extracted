use Test::Cmd;
use Test2::Bundle::More;
use Cwd;
use File::Temp;

plan tests => 5;

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
  # remove files
  unlink glob $resultsDir."/*.*"
}
my $archiveDir =  $dir.'/t/archive';
my $dataDir =  $dir.'/t/data';

# NOTE: putting the args in the prog can cause trouble
# when -f type args are passed: so keep the args argument separate
$test->run(
  interpreter => 'perl',
  prog => 'bin/inicat',
  args => $dataDir.'/sample.ini',
  verbose => 1,
);
# grab stdout before anything else happens
my $stdoutStr = $test->stdout;
$stdoutStr = removeLineEndings($stdoutStr);
$test->read(\$archive, $archiveDir.'/result_cat_sample.ini');
$archive = removeLineEndings($archive);
is($stdoutStr, $archive, 'inicat: write to stdout');

$test->run(
  prog => 'bin/inicat',
  interpreter => 'perl',
  args => '-o '.$resultsDir.'/result_cat_sample.ini '.$dataDir.'/sample.ini',
);
$test->read(\$result, $resultsDir.'/result_cat_sample.ini');
$result = removeLineEndings($result);
is( $result, $archive, 'inicat: write to output file');
is( $? >> 8,       1,       'exit status' );

$test->run(
  prog => 'bin/inicat',
  interpreter => 'perl',
  args => '-o '.$resultsDir.'/result_cat_sample_duplicate_section.ini '.$dataDir.'/sample_duplicate_section.ini',
);
$test->write($resultsDir.'/result_cat_sample_duplicate_section.ini', $test->stderr);
like($test->stderr, qr/duplicate key: onekey/, 'inicat: duplicate section');
is( $? >> 8,       0,       'exit status' );
