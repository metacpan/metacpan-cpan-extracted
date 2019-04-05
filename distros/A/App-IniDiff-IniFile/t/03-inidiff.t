use Test::Cmd;
use Test2::Bundle::More;
use Cwd;
use File::Temp;

plan tests => 15;

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

$test->run(
  interpreter => 'perl',
  prog => 'bin/inidiff',
  args =>  '-o - '.$dataDir.'/sample.ini '.$dataDir.'/result_cat_sample.ini',
  # verbose => 1,
);
# grab stdout before anything else happens
my $stdoutStr = $test->stdout;
$stdoutStr = removeLineEndings($stdoutStr);
# won't write an empty INI file
$test->read(\$archive, $archiveDir.'/result_cat_test.ini');
$archive = removeLineEndings($archive);
is( $stdoutStr, $archive, 'inidiff: compare identical' );

$test->run(
  interpreter => 'perl',
  prog => 'bin/inidiff',
  args => '-o '.$resultsDir.'/result_inidiff_add_section_nc_test.ini -q '.$dataDir.'/sample.ini '.$resultsDir.'/result_add_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_add_section_nc_test.ini');
$archive = removeLineEndings($archive);
$test->read(\$result, $resultsDir.'/result_inidiff_add_section_nc_test.ini');
$result = removeLineEndings($result);
is( $result, $archive, 'inidiff: add section no comments' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'bin/inidiff',
  args =>  '-o '.$resultsDir.'/result_inidiff_add_section_wc_test.ini '.$dataDir.'/sample.ini '.$resultsDir.'/result_add_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_add_section_wc_test.ini');
$archive = removeLineEndings($archive);
$test->read(\$result, $resultsDir.'/result_inidiff_add_section_wc_test.ini');
$result = removeLineEndings($result);
is( $result, $archive, 'inidiff: add section with comments' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'bin/inidiff',
  args =>  '-o '.$resultsDir.'/result_del_section_test.ini '.$dataDir.'/sample.ini '.$resultsDir.'/result_del_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_del_section_test.ini');
$archive = removeLineEndings($archive);
$test->read(\$result, $resultsDir.'/result_del_section_test.ini');
$result = removeLineEndings($result);
is( $result, $archive, 'inidiff: delete section' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'bin/inidiff',
  args => '-o '.$resultsDir.'/result_inidiff_del_section_nc_test.ini -q '.$resultsDir.'/result_add_section_nc.ini '.$resultsDir.'/result_del_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_del_section_nc_test.ini');
$archive = removeLineEndings($archive);
$test->read(\$result, $resultsDir.'/result_inidiff_del_section_nc_test.ini');
$result = removeLineEndings($result);
is( $result, $archive, 'inidiff: del section no comments' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'bin/inidiff',
  args => '-o '.$resultsDir.'/result_inidiff_del_section_wc_test.ini '.$resultsDir.'/result_add_section_nc.ini '.$resultsDir.'/result_del_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_del_section_wc_test.ini');
$archive = removeLineEndings($archive);
$test->read(\$result, $resultsDir.'/result_inidiff_del_section_wc_test.ini');
$result = removeLineEndings($result);
is( $result, $archive, 'inidiff: del section with comments' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'bin/inidiff',
  args => '-o '.$resultsDir.'/result_inidiff_add_setting_nc_test.ini -q '.$resultsDir.'/result_add_section_nc.ini '.$resultsDir.'/result_add_setting_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_add_setting_nc_test.ini');
$archive = removeLineEndings($archive);
$test->read(\$result, $resultsDir.'/result_inidiff_add_setting_nc_test.ini');
$result = removeLineEndings($result);
is( $result, $archive, 'inidiff: add setting no comments' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'bin/inidiff',
  args => '-o '.$resultsDir.'/result_inidiff_add_setting_wc_test.ini '.$resultsDir.'/result_add_section_nc.ini '.$resultsDir.'/result_add_setting_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_add_setting_wc_test.ini');
$archive = removeLineEndings($archive);
$test->read(\$result, $resultsDir.'/result_inidiff_add_setting_wc_test.ini');
$result = removeLineEndings($result);
is( $result, $archive, 'inidiff: add setting with comments' );
is( $? >> 8,       0,       'exit status' );


