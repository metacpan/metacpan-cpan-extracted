use v5.36;

use lib ".";
use t::Util qw(run);

my @tests = (
    {
        Name                   => 'default',
        args                   => [],
        expected_error_message => '',
        expected_stdout        => qr/^\S+\s\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'name',
        args                   => ['name'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+\s\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'male',
        args                   => ['male'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+\s\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'female',
        args                   => ['female'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+\s\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'address',
        args                   => ['address'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'not supported',
        args                   => ['NOT_SUPPORTED'],
        expected_error_message => "Error: unknown word_type: NOT_SUPPORTED\n",
        expected_stdout        => '',
        expected_stderr        => '',
    },
);
run(@tests);
