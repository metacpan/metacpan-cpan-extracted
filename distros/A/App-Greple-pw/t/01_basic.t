use v5.18;
use utf8;
use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

# Test basic module loading and functionality
my $result = pw(qw(--usage))->run;
is($result->{result} >> 8, 2, "pw module loads successfully (usage returns 2)");
like($result->stdout, qr/App::Greple::pw options:/, "pw module options shown in usage");

# Test simple pattern matching without interactive mode
my $test_data = <<'EOF';
User: testuser
Password: secret123
Account: myaccount
PIN: 1234
EOF

# Test that module loads and finds pattern
my $simple_result = pw('-c', 'User')->setstdin($test_data)->run;
is($simple_result->{result} >> 8, 0, "simple pattern matching works");
like($simple_result->stdout, qr/1/, "finds one match for 'User'");

# Test that configuration is accessible
my $config_result = pw('--config', 'debug=1', '--', '-c', 'User')->setstdin($test_data)->run;
is($config_result->{result} >> 8, 0, "config parameter works");

done_testing;
