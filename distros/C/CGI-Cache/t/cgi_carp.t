use File::Temp;
use Test::More;

use strict;
use lib 't';
use Test::Utils;
use File::Path;
use CGI::Cache;
use File::Basename;

use vars qw( $VERSION );

$VERSION = sprintf "%d.%02d%02d", q/0.10.0/ =~ /(\d+)/g;

my $TEMPDIR = File::Temp::tempdir();

# ----------------------------------------------------------------------------

unless(eval 'require CGI::Carp')
{
  plan skip_all => 'CGI::Carp not installed';
  exit;
}

plan tests => 7;

# ----------------------------------------------------------------------------

my $script_number = 1;

# ----------------------------------------------------------------------------

# Test 1-3: caching with default attributes
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;
use CGI::Carp qw(fatalsToBrowser set_message);

CGI::Cache::setup({ cache_options => { cache_root => '$TEMPDIR' } });
CGI::Cache::set_key('test key');
CGI::Cache::start() or exit;

die ("Good day to die\n");
EOF

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

my $short_script_name = fileparse($test_script_name);

my $expected_stdout = qr/Content-type: text\/html.*<pre>Good day to die/si;
my $expected_stderr = qr/\[[^\]]+:[^\]]+\] $short_script_name: Good day to die/si;
my $expected_cached = undef;
my $message = "CGI::Carp not caching with default attributes";

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;
}

# ----------------------------------------------------------------------------

# Test 4 There should be nothing in the cache directory until we actually cache something
ok(!defined(<$TEMPDIR/*>), 'Empty cache directory until something cached');

# ----------------------------------------------------------------------------

# Test 5-7: caching with default attributes
{
my $script = <<EOF;
use lib '../blib/lib';
use CGI::Cache;
use CGI::Carp qw(fatalsToBrowser set_message);

CGI::Cache::setup({ cache_options => { cache_root => '$TEMPDIR' } });
CGI::Cache::set_key('test key');
CGI::Cache::start() or exit;

print ("Good day to live\n");
EOF

my $expected_stdout = "Good day to live\n";
my $expected_stderr = '';
my $expected_cached = "Good day to live\n";
my $message = "CGI::Carp caching with default attributes";

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX', TMPDIR=>1);

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;
}

# ----------------------------------------------------------------------------

# Cleanup
rmtree $TEMPDIR;
