use File::Temp;
use Test::More tests => 6;

use strict;
use lib 't';
use File::Path;
use Test::Utils;
use CGI::Cache;

use File::Slurper qw(read_text write_text);

use vars qw( $VERSION );

$VERSION = sprintf "%d.%02d%02d", q/0.10.0/ =~ /(\d+)/g;

my $TEMPDIR = File::Temp::tempdir();

# ----------------------------------------------------------------------------

my $script_number = 1;

# ----------------------------------------------------------------------------

# Test 1-3: Output to filehandle other than STDOUT
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;

use File::Slurper qw(read_text);

open FH, ">TEST.OUT";

CGI::Cache::setup({ cache_options => { cache_root => '$TEMPDIR' },
                    output_handle => \\*FH } );
CGI::Cache::set_key( 'test key' );
CGI::Cache::start() or die "Should not have cached output for this test\n";

print "Test output 1\n";

CGI::Cache::stop();

close FH;

my \$results = read_text('TEST.OUT', undef, 1);

unlink "TEST.OUT";

print "RESULTS: \$results";
EOF

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

write_text($test_script_name, $script);
Setup_Cache($test_script_name,$script,1);

my $expected_stdout = "RESULTS: Test output 1\n";
my $expected_stderr = '';
my $expected_cached = "Test output 1\n";
my $message = 'Output to non-STDOUT filehandle';

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
$TEMPDIR = File::Temp::tempdir();
}

# ----------------------------------------------------------------------------

# Test 4-6: Monitor a filehandle other than STDOUT
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;
use File::Slurper qw(read_text);

open FH, ">TEST.OUT";

CGI::Cache::setup( { cache_options => { cache_root => '$TEMPDIR' },
                     watched_output_handle => \\*FH } );
CGI::Cache::set_key( 'test key' );
CGI::Cache::start() or die "Should not have cached output for this test\n";

print FH "Test output 1\n";

CGI::Cache::stop();

close FH;

my \$results = read_text('TEST.OUT', undef, 1);

unlink "TEST.OUT";

print "RESULTS: \$results";
EOF

my $expected_stdout = "RESULTS: Test output 1\n";
my $expected_stderr = '';
my $expected_cached = "Test output 1\n";
my $message = 'Monitor non-STDOUT filehandle';

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
}
