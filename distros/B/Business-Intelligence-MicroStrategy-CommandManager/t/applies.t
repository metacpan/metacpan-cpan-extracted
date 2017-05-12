#!perl -T

use Test::More;
use strict;
use warnings;

my $tests;

BEGIN {
    $tests = 2;
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib';
}

use Business::Intelligence::MicroStrategy::CommandManager;
my $foo = Business::Intelligence::MicroStrategy::CommandManager->new();

is(
    $foo->apply_run_time_settings,
    'APPLY RUN TIME SETTINGS;',
    "apply_run_time_settings"
);
is(
    $foo->apply_security_filter(
        SECURITY_FILTER          => "SecFilter1",
        LOCATION                 => '\Project Objects\MD Security Filters',
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        PROJECT                  => "MicroStrategy Tutorial"
    ),
'APPLY SECURITY FILTER "SecFilter1" FOLDER "\Project Objects\MD Security Filters" TO USER "Developer" ON PROJECT "MicroStrategy Tutorial";',
    "apply_security_filter"
);
