use v5.36;

use lib ".";
use t::Util qw(run);

my @tests = (
    {
        Name                   => 'long form',
        args                   => ['-version'],
        expected_error_message => '',
        expected_stdout        => "$App::Gimei::VERSION\n",
        expected_stderr        => '',
    },
    {
        Name                   => 'short form',
        args                   => ['-v'],
        expected_error_message => '',
        expected_stdout        => "$App::Gimei::VERSION\n",
        expected_stderr        => '',
    },
);
run(@tests);
