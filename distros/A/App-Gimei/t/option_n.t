use v5.36;

use lib ".";
use t::Util qw(run);

my @tests = (
    {
        Name                   => 'number expected',
        args                   => [ '-n', 'Alice' ],
        expected_error_message =>
          "Error: Value \"Alice\" invalid for option n (number expected)\n",
        expected_stdout => '',
        expected_stderr => '',
    },
    {
        Name                   => 'positive number expected',
        args                   => [ '-n', '-1' ],
        expected_error_message =>
          "Error: value -1 invalid for option n (must be positive number)\n",
        expected_stdout => '',
        expected_stderr => '',
    },
    {
        Name                   => '-n 1',
        args                   => [ '-n', '1' ],
        expected_error_message => '',
        expected_stdout        => qr/^\S+\s\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => '-n 2',
        args                   => [ '-n', '2', 'name:family' ],
        expected_error_message => '',
        expected_stdout        => qr/^\S+\n\S+$/,
        expected_stderr        => '',
    },
);
run(@tests);
