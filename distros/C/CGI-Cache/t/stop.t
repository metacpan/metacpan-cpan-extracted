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

# Test 1-3: that stop() actually stops caching output
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;

CGI::Cache::setup({ cache_options => { cache_root => '$TEMPDIR' } });
CGI::Cache::set_key( {2 => 'test key 3', 1 => 'test', 3 => 'key'} );
CGI::Cache::start() or exit;

print "Test output 5\n";

CGI::Cache::stop();

print "Test uncached output 5\n";
EOF

my $expected_stdout = "Test output 5\nTest uncached output 5\n";
my $expected_stderr = '';
my $expected_cached = "Test output 5\n";
my $message = 'stop()';

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
$TEMPDIR = File::Temp::tempdir();
}

# ----------------------------------------------------------------------------

# Test 4-6: that stop() actually stops caching output. (set handles)
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;

CGI::Cache::setup( { cache_options => { cache_root => '$TEMPDIR' },
                     watched_output_handle => \\*STDOUT,
                     watched_error_handle => \\*STDERR,
                     output_handle => \\*STDOUT,
                     error_handle => \\*STDERR } );
CGI::Cache::set_key( {2 => 'test key 3', 1 => 'test', 3 => 'key'} );
CGI::Cache::start() or exit;

print "Test output 5\n";

CGI::Cache::stop();

print "Test uncached output 5\n";
EOF

my $expected_stdout = "Test output 5\nTest uncached output 5\n";
my $expected_stderr = '';
my $expected_cached = "Test output 5\n";
my $message = 'stop() with filehandles';

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
}

# ----------------------------------------------------------------------------

