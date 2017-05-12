#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('DBIx::Class::ResultSet::Void');
}

diag(
"Testing DBIx::Class::ResultSet::Void $DBIx::Class::ResultSet::Void::VERSION, Perl $], $^X"
);
