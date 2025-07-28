use v5.18;
use utf8;
use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

# Test data for option tests
my $test_data = "User: testuser\nPassword: secret123\n";

# Test command-line options with hyphens
my $hyphen_result = pw(qw(--no-clear-screen -- -c User))->setstdin($test_data)->run;
is($hyphen_result->{result} >> 8, 0, "hyphenated options work");

# Test debug option
my $debug_result = pw(qw(--debug -- -c User))->setstdin($test_data)->run;
is($debug_result->{result} >> 8, 0, "--debug option works");

# Test browser option
my $browser_result = pw(qw(--browser=safari -- -c User))->setstdin($test_data)->run;
is($browser_result->{result} >> 8, 0, "--browser option works");

# Test timeout option
my $timeout_result = pw(qw(--timeout=600 -- -c User))->setstdin($test_data)->run;
is($timeout_result->{result} >> 8, 0, "--timeout option works");

# Test combination of config and command-line options
my $combo_result = pw(qw(--config debug=1 --debug -- -c User))->setstdin($test_data)->run;
is($combo_result->{result} >> 8, 0, "config and command-line options work together");

# Test browser shortcuts (these are command options, not module options)
my $chrome_result = pw(qw(--chrome -c User))->setstdin($test_data)->run;
is($chrome_result->{result} >> 8, 0, "--chrome shortcut works");

my $safari_result = pw(qw(--safari -c User))->setstdin($test_data)->run;
is($safari_result->{result} >> 8, 0, "--safari shortcut works");

done_testing;
