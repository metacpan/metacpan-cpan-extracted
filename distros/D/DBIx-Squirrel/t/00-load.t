use 5.010_001;
use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Test::More;

BEGIN {
    use_ok('DBIx::Squirrel') || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

done_testing();
