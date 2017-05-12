#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Config::YAML::Modern') || print "Bail out!\n";
}

diag("Testing Config::YAML::Modern $Config::YAML::Modern::VERSION, Perl $], $^X"
);
