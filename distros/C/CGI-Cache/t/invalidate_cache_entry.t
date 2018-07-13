use File::Temp;
use Test::More tests => 6;

use strict;
use lib 't';
use File::Path;
use Test::Utils;
use CGI::Cache;

use vars qw( $VERSION );

$VERSION = sprintf "%d.%02d%02d", q/0.10.0/ =~ /(\d+)/g;

my $TEMPDIR = File::Temp::tempdir();

# ----------------------------------------------------------------------------

my $script_number = 1;

# ----------------------------------------------------------------------------

# Test 1-6: test that invalidate_cache_entry() removes the cache entry
{

# Do the first run to set up the cached data
{
  my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;

CGI::Cache::setup({ cache_options => { cache_root => '$TEMPDIR' } });
CGI::Cache::set_key('test key');
CGI::Cache::start() or exit;

print "Test output 1\n";

sleep 2;
EOF

  my $expected_stdout = "Test output 1\n";
  my $expected_stderr = '';
  my $expected_cached = "Test output 1\n";
  my $message = 'invalidate_cache_entry() setup';

  my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

  Init_For_Run($test_script_name, $script, 1);
  Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);
}

# Now run a script that invalidates the previous cached content before
# printing new cached content
{
  my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;

CGI::Cache::setup( { cache_options => {
                     cache_root => '$TEMPDIR',
                     filemode => 0666,
                     max_size => 20 * 1024 * 1024,
                     default_expires_in => 6 * 60 * 60,
                   } } );
CGI::Cache::set_key( ['test key',1,2] );
CGI::Cache::invalidate_cache_entry();
CGI::Cache::start() or exit;

print "Test output 2\n";
EOF

  my $expected_stdout = "Test output 2\n";
  my $expected_stderr = '';
  my $expected_cached = "Test output 2\n";
  my $message = 'invalidate_cache_entry() operation';

  my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

  Init_For_Run($test_script_name, $script, 1);
  Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);
}

$script_number++;

rmtree $TEMPDIR;
}

