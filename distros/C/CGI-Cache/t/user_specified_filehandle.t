use File::Temp;
use Test::More tests => 6;

use strict;
use lib 't';
use File::Path;
use Test::Utils;
use CGI::Cache;

# http://www.cpantesters.org/cpan/report/9373ce6a-e71a-11e4-9f23-cdc1e0bfc7aa
BEGIN {
  $SIG{__WARN__} = sub {
    my $warning = shift;
    warn $warning unless $warning =~ /Subroutine .* redefined at/;
  };
  use File::Slurp;
  $SIG{__WARN__} = undef;
};

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

# http://www.cpantesters.org/cpan/report/9373ce6a-e71a-11e4-9f23-cdc1e0bfc7aa
BEGIN {
  \$SIG{__WARN__} = sub {
    my \$warning = shift;
    warn \$warning unless \$warning =~ /Subroutine .* redefined at/;
  };
  use File::Slurp;
  \$SIG{__WARN__} = undef;
};

open FH, ">TEST.OUT";

CGI::Cache::setup({ cache_options => { cache_root => '$TEMPDIR' },
                    output_handle => \\*FH } );
CGI::Cache::set_key( 'test key' );
CGI::Cache::start() or die "Should not have cached output for this test\n";

print "Test output 1\n";

CGI::Cache::stop();

close FH;

my \$results = read_file('TEST.OUT');

unlink "TEST.OUT";

print "RESULTS: \$results";
EOF

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX');

write_file($test_script_name, $script);
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
use File::Slurp;

open FH, ">TEST.OUT";

CGI::Cache::setup( { cache_options => { cache_root => '$TEMPDIR' },
                     watched_output_handle => \\*FH } );
CGI::Cache::set_key( 'test key' );
CGI::Cache::start() or die "Should not have cached output for this test\n";

print FH "Test output 1\n";

CGI::Cache::stop();

close FH;

my \$results = read_file('TEST.OUT');

unlink "TEST.OUT";

print "RESULTS: \$results";
EOF

my $expected_stdout = "RESULTS: Test output 1\n";
my $expected_stderr = '';
my $expected_cached = "Test output 1\n";
my $message = 'Monitor non-STDOUT filehandle';

my (undef, $test_script_name) = File::Temp::tempfile('cgi_test.cgi.XXXXX');

Init_For_Run($test_script_name, $script, 1);
Run_Script($test_script_name, $expected_stdout, $expected_stderr, $expected_cached, $message);

$script_number++;

rmtree $TEMPDIR;
}
