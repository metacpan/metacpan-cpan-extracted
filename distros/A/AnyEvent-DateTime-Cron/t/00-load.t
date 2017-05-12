#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('AnyEvent::DateTime::Cron') || print "Bail out!
";
}

diag(
    "Testing AnyEvent::DateTime::Cron $AnyEvent::DateTime::Cron::VERSION, Perl $], $^X"
);

done_testing;
