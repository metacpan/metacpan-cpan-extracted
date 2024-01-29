use v5.36;

use lib ".";
use t::Util qw(run);

my @tests = (
    {
        Name                   => 'default',
        args                   => ['name'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+\s\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'address->romaji',
        args                   => ['address:romaji'],
        expected_error_message =>
          "Error: rendering romaji is not supported for address\n",
        expected_stdout => '',
        expected_stderr => '',
    },
    {
        Name                   => 'gender',
        args                   => ['name:gender'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'kanji',
        args                   => ['name:kanji'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+\s\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'hiragana',
        args                   => ['name:family:hiragana'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'katakana',
        args                   => ['address:katakana'],
        expected_error_message => '',
        expected_stdout        => qr/^\S+$/,
        expected_stderr        => '',
    },
    {
        Name                   => 'unknown rendering',
        args                   => ['address:prefecture:romaji'],
        expected_error_message =>
          "Error: rendering romaji is not supported for address\n",
        expected_stdout => '',
        expected_stderr => '',
    },
);
run(@tests);
