use strict;
use warnings;
use Test::More;
use App::Test::Generator qw(generate);

my $conf_file = "t/conf/add.conf";
ok(-e $conf_file, "config file exists: $conf_file");

# Generate into a scalar
{
    local *STDOUT;
    open STDOUT, '>', \my $output;
    App::Test::Generator::generate($conf_file);
    like($output, qr/use Test::Most;/, "output looks like a test file");
}

done_testing;
