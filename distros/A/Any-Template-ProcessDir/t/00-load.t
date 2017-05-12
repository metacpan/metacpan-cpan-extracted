#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Any::Template::ProcessDir');
}

diag(
    "Testing Any::Template::ProcessDir $Any::Template::ProcessDir::VERSION, Perl $], $^X"
);
