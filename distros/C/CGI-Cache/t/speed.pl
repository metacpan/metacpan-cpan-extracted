use File::Temp;
use Test::More;

use strict;
use lib 't';
use Test::Utils;
use File::Path;
use CGI::Cache;
use Benchmark::Timer;

use vars qw( $VERSION );

$VERSION = sprintf "%d.%02d%02d", q/0.10.2/ =~ /(\d+)/g;

my $TEMPDIR = File::Temp::tempdir();

BEGIN
{
  die "Need Benchmark::Timer 0.6 or higher" unless $Benchmark::Timer::VERSION >= 0.6;
}

# ----------------------------------------------------------------------------

sub Time_Script
{
  my $script = shift;
  my $expected_stdout = shift;
  my $message = shift; 
  
  my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

  my $t = Benchmark::Timer->new(skip => 1, confidence => 95, error => 5, minimum => 3);
  my $total_tests = 0;

  while($t->need_more_samples('first run')) {
    Init_For_Run($test_script_name, $script, 1);

    $t->start('first run');

    # Three tests in Run_Script
    Run_Script($test_script_name, $expected_stdout, '', '<SKIP>', "$message (first run)");
    $total_tests += 3;
  
    $t->stop('first run');
  }

  my $t1 = $t->result('first run');
    
  #  Second run should be short, but return output from cache
  while($t->need_more_samples('second run')) {
    Init_For_Run($test_script_name, $script, 0);

    $t->start('second run');

    # Three tests in Run_Script
    Run_Script($test_script_name, $expected_stdout, '', '<SKIP>', "$message (second run)");
    $total_tests += 3;
  
    $t->stop('second run');
  }

  my $t2 = $t->result('second run');

  #  Do a cursory check to see that it was at least a little
  #  faster with the cached file, only if $t2 != 0;
  SKIP: {
    skip "Both runs were too fast to compare", 1 if $t2 == 0 && $t1 == 0;

    ok($t2 == 0 || $t1/$t2 >= 1.5, "$message: Caching run was faster -- $t2 versus $t1");
    $total_tests += 1;
  }

  return $total_tests;
}

# ---------------------------------------------------------------------------

my $total_tests = 0;

# Test 1-7: caching with default attributes
$total_tests += Time_Script(<<EOF,"Test output 1\n","Default attributes");
use CGI::Cache;

CGI::Cache::setup({ cache_options => { cache_root => '$TEMPDIR' } });
CGI::Cache::set_key('test key');
CGI::Cache::start() or exit;

print "Test output 1\n";

sleep 3;
EOF

# Clean up
rmtree $TEMPDIR;
$TEMPDIR = File::Temp::tempdir();

# ----------------------------------------------------------------------------

# Test 8-14: caching with some custom attributes, and with a complex data
# structure
$total_tests += Time_Script(<<EOF,"Test output 2\n","Custom attributes");
use CGI::Cache;

CGI::Cache::setup( { cache_options => { 
                     cache_root => '$TEMPDIR',
                     filemode => 0666,
                     max_size => 20 * 1024 * 1024,
                     default_expires_in => 6 * 60 * 60,
                   } } );
CGI::Cache::set_key( ['test key 2',1,2] );
CGI::Cache::start() or exit;

print "Test output 2\n";

sleep 3;
EOF

# Clean up
rmtree $TEMPDIR;
$TEMPDIR = File::Temp::tempdir();

# ----------------------------------------------------------------------------

# Test 15-21 caching with default attributes. (set handles)
$total_tests += Time_Script(<<EOF,"Test output 1\n","Set handles");
use CGI::Cache;

CGI::Cache::setup( { cache_options => { cache_root => '$TEMPDIR' },
                     watched_output_handle => \\*STDOUT,
                     watched_error_handle => \\*STDERR,
                     output_handle => \\*STDOUT,
                     error_handle => \\*STDERR } );
CGI::Cache::set_key('test key');
CGI::Cache::start() or exit;

print "Test output 1\n";

sleep 3;
EOF

# Clean up
rmtree $TEMPDIR;

done_testing($total_tests);
