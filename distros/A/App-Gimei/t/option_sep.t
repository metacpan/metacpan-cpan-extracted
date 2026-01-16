use v5.40;

use lib ".";
use t::Util qw(run);

my @tests = (
    {
        Name                   => '-sep :',
        args                   => [ '-sep', ':' ],
        expected_stdout        => qr/^\S+\s\S+$/,
        expected_stderr        => '',
        expected_error_message => '',
    },
    {
        Name                   => '-sep : pref, city',
        args                   => [ '-sep', ':', 'address:prefecture', 'address:city' ],
        expected_stdout        => qr/^[^:]+:[^:]+$/,
        expected_stderr        => '',
        expected_error_message => '',
    },
);

run(@tests);
