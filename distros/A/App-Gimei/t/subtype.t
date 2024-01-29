use v5.36;

use lib ".";
use t::Util qw(run);

my @tests = (
    {
        Name                   => 'family',
        args                   => ['name:family'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'last',
        args                   => ['name:last'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'given',
        args                   => ['male:given'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'first',
        args                   => ['female:first'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'gender',
        args                   => ['name:gender'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'sex',
        args                   => ['name:sex'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'unknown',
        args                   => ['female:unknown'],
        expected_error_message => "Error: unknown subtype or rendering: unknown\n",
        expected_stdout        => '',
        expected_stderr        => '',
    },
    {
        Name                   => 'prefecture',
        args                   => ['address:prefecture'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'city',
        args                   => ['address:city'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'town',
        args                   => ['address:town'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'unknown',
        args                   => ['address:unknown'],
        expected_error_message => "Error: unknown subtype or rendering: unknown\n",
        expected_stdout        => '',
        expected_stderr        => '',
    },
);
run(@tests);
