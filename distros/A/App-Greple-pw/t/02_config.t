use v5.18;
use utf8;
use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

# Test data for config tests
my $test_data = "User: testuser\nPassword: secret123\n";

# Test --config parameter usage
my $config_result = pw(qw(--config clear_screen=0 -- -c User))->setstdin($test_data)->run;
is($config_result->{result} >> 8, 0, "--config parameter works");

# Module config syntax (::config=) cannot be tested with current Util.pm design
# pw() function adds arguments after '-Mpw', but ::config= needs to be part of module name
# This would require: greple -Mpw::config=debug=1 (not: greple -Mpw ::config=debug=1)

# Test multiple config parameters
my $multi_config_result = pw(qw(--config clear_screen=0 --config debug=1 -- -c User))->setstdin($test_data)->run;
is($multi_config_result->{result} >> 8, 0, "multiple config parameters work");

# Test boolean config parameters
my $bool_result = pw(qw(--config clear_clipboard=0 -- -c User))->setstdin($test_data)->run;
is($bool_result->{result} >> 8, 0, "boolean config parameter works");

# Test string config parameters
my $string_result = pw(qw(--config browser=firefox -- -c User))->setstdin($test_data)->run;
is($string_result->{result} >> 8, 0, "string config parameter works");

done_testing;
