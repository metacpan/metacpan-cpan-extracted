use File::Temp;
use Test::More tests => 15;

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

# Tests 1-3: that a script with an error doesn't cache output
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;

CGI::Cache::setup({ cache_options => { cache_root => '$TEMPDIR' } });
CGI::Cache::set_key( {2 => 'test key 3', 1 => 'test', 3 => 'key'} );
CGI::Cache::start() or exit;

print "Test output 1\n";

die "Forced die!\n";
EOF

my $expected_stdout = "Test output 1\n";
my $expected_stderr = "Forced die!\n";
my $expected_cached = undef;
my $message = 'die() prevents caching';

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
$TEMPDIR = File::Temp::tempdir();
}

# ----------------------------------------------------------------------------

# Test 4: There should be nothing in the cache directory until we actually cache something
ok(!defined(<$TEMPDIR/*>), 'Empty cache directory until something cached');

# ----------------------------------------------------------------------------

# Test 5-7: that a script that prints to STDERR doesn't cache output
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;

CGI::Cache::setup( { cache_options => { cache_root => '$TEMPDIR' } } );
CGI::Cache::set_key( {2 => 'test key 3', 1 => 'test', 3 => 'key'} );
CGI::Cache::start() or exit;

print "Test output 1\n";

print STDERR "STDERR!\n";
EOF

my $expected_stdout = "Test output 1\n";
my $expected_stderr = "STDERR!\n";
my $expected_cached = undef;
my $message = 'Print to STDERR prevents caching';

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
$TEMPDIR = File::Temp::tempdir();
}

# ----------------------------------------------------------------------------

# Test 8: There should be nothing in the cache directory until we actually cache something
ok(!defined(<$TEMPDIR/*>), 'Empty cache directory until something cached');

# ----------------------------------------------------------------------------

# Tests 9-11: that a script that calls a redirected die doesn't cache output
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;

\$SIG{__DIE__} = sub { print STDOUT \@_;exit 1 };

CGI::Cache::setup( { cache_options => { cache_root => '$TEMPDIR' } } );
CGI::Cache::set_key( {2 => 'test key 3', 1 => 'test', 3 => 'key'} );
CGI::Cache::start() or exit;

print "Test output 1\n";

die "STDERR!\n";
EOF

my $expected_stdout = "Test output 1\nSTDERR!\n";
my $expected_stderr = "";
my $expected_cached = undef;
my $message = 'redirected die() prevents caching';

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
$TEMPDIR = File::Temp::tempdir();
}

# ----------------------------------------------------------------------------

# Test 12 There should be nothing in the cache directory until we actually cache something
ok(!defined(<$TEMPDIR/*>), 'Empty cache directory until something cached');

# ----------------------------------------------------------------------------

# Test 13-15: that a script with an error doesn't cache output. (set handles)
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

print "Test output 1\n";

die "Forced die!\n";
EOF

my $expected_stdout = "Test output 1\n";
my $expected_stderr = "Forced die!\n";
my $expected_cached = undef;
my $message = 'die() (with filehandles) prevents caching';

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX');

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
}
