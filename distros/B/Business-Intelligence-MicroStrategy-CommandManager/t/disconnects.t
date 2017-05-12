#!perl -T

use Test::More;
use strict;
use warnings;

my $tests;

BEGIN {
    $tests = 4;
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib';
}

use Business::Intelligence::MicroStrategy::CommandManager;
my $foo = Business::Intelligence::MicroStrategy::CommandManager->new();

is(
    $foo->disconnect_database_connection("ALL"),
    'DISCONNECT ALL DATABASE CONNECTIONS;',
    "disconnect_database_connection1"
);

is(
    $foo->disconnect_database_connection(4),
    'DISCONNECT DATABASE CONNECTION 4;',
    "disconnect_database_connection"
);

is(
    $foo->disconnect_user(
        PROJECT      => "project_name",
        ALL_SESSIONS => "TRUE"
    ),
    'DISCONNECT ALL USER SESSIONS FROM PROJECT "project_name";',
    "disconnect_user"
);

is(
    $foo->disconnect_user( SESSIONID => 4 ),
    'DISCONNECT USER SESSIONID 4;',
    "disconnect_user"
);
