use v5.36;

use lib ".";
use t::Util qw(run);

my @tests = (
    {
        Name                   => 'long form',
        args                   => ['-help'],
        expected_error_message => '',
        expected_stdout        => qr/^Usage:/,
        expected_stderr        => '',
    },
    {
        Name                   => 'short form',
        args                   => ['-h'],
        expected_error_message => '',
        expected_stdout        => qr/^Usage:/,
        expected_stderr        => '',
    },
);
run(@tests);
