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

# Test 1-3: test buffer() with no arguments
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;

CGI::Cache::setup({ cache_options => { cache_root => '$TEMPDIR' } });
CGI::Cache::set_key( 'test key' );
CGI::Cache::start() or exit;

print "Test output 1\n";
my \$buffer = CGI::Cache::buffer();
CGI::Cache::stop();
print "BUFFER: \$buffer";
EOF

my $expected_stdout = "Test output 1\nBUFFER: Test output 1\n";
my $expected_stderr = '';
my $expected_cached = "Test output 1\n";
my $message = 'read buffer()';

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX');

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
$TEMPDIR = File::Temp::tempdir();
}

# ----------------------------------------------------------------------------

# Test 4-6: test buffer() with arguments
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;

CGI::Cache::setup({ cache_options => { cache_root => '$TEMPDIR' } });
CGI::Cache::set_key( 'test key' );
CGI::Cache::start() or exit;

print "Test output 1\n";
CGI::Cache::buffer("Replacement output 1\n");
print "Test output 2\n";
EOF

my $expected_stdout = "Test output 1\nTest output 2\n";
my $expected_stderr = '';
my $expected_cached = "Replacement output 1\nTest output 2\n";
my $message = 'write buffer()';

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX');

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
}
