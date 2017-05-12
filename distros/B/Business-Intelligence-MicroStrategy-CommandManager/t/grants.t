#!perl -T

use Test::More;
use strict;
use warnings;

my $tests;

BEGIN {
    $tests = 5;
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib';
}

use Business::Intelligence::MicroStrategy::CommandManager;
my $foo = Business::Intelligence::MicroStrategy::CommandManager->new();

is(
    $foo->grant_privileges(
        PRIVILEGE => [
            qw(CREATESCHEMAOBJECTS SCHEDULEREQUEST USEOBJECTMANAGER USEVLDBEDITOR)
        ],
        USER => "Developer",
    ),
'GRANT CREATESCHEMAOBJECTS, SCHEDULEREQUEST, USEOBJECTMANAGER, USEVLDBEDITOR TO USER "Developer";',
    "grant_privileges1"
);

is(
    $foo->grant_privileges(
        PRIVILEGE =>
          [qw(WEBDRILLING WEBEXPORT WEBOBJECTSEARCH WEBSORT WEBUSER WEBADMIN)],
        GROUP => "Managers",
    ),
'GRANT WEBDRILLING, WEBEXPORT, WEBOBJECTSEARCH, WEBSORT, WEBUSER, WEBADMIN TO GROUP "Managers";',
    "grant_privileges2"
);

is(
    $foo->grant_privileges(
        PRIVILEGE => [qw(USESERVERCACHE USECUSTOMGROUPEDITOR USEMETRICEDITOR)],
        SECURITY_ROLE => "Normal Users"
    ),
'GRANT USESERVERCACHE, USECUSTOMGROUPEDITOR, USEMETRICEDITOR TO SECURITY ROLE "Normal Users";',
    "grant_privileges3"
);

is(
    $foo->grant_security_roles(
        SECURITY_ROLE => "Power Users",
        GROUP         => "Managers",
        PROJECT       => "MicroStrategy Tutorial"
    ),
'GRANT SECURITY ROLE "Power Users" TO GROUP "Managers" ON PROJECT "MicroStrategy Tutorial";',
    "grant_security_roles1"
);

is(
    $foo->grant_security_roles(
        SECURITY_ROLE => "Normal Users",
        USER          => "Developer",
        PROJECT       => "MicroStrategy Tutorial"
    ),
'GRANT SECURITY ROLE "Normal Users" TO USER "Developer" ON PROJECT "MicroStrategy Tutorial";',
    "grant_security_roles2"
);

