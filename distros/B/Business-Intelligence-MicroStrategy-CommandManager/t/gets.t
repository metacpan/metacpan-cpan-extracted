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

my %parms = ( '' => '', );

is(
    $foo->get_attribute_child_candidates(
        ATTRIBUTE => "attribute_name",
        LOCATION  => "location_path",
        PROJECT   => "project_name"
    ),
'GET CHILD CANDIDATES FOR ATTRIBUTE "attribute_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "get_attribute_child_candidates"
);

is(
    $foo->get_attribute_parent_candidates(
        ATTRIBUTE => "attribute_name",
        LOCATION  => "location_path",
        PROJECT   => "project_name"
    ),
'GET PARENT CANDIDATES FOR ATTRIBUTE "attribute_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "get_attribute_parent_candidates"
);

is(
    $foo->get_object_property(
        PROPERTIES => [
            qw(NAME ID DESCRIPTION LOCATION CREATIONTIME MODIFICATIONTIME OWNER LONGDESCRIPTION HIDDEN)
        ],
        PROJECT_CONFIG_OBJECT => "REPORT",
        OBJECT_NAME           => "object_name",
        LOCATION              => "location_path",
        PROJECT               => "project_name"
    ),
'GET PROPERTIES NAME, ID, DESCRIPTION, LOCATION, CREATIONTIME, MODIFICATIONTIME, OWNER, LONGDESCRIPTION, HIDDEN FROM REPORT "object_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "get_object_property"
);
is(
    $foo->get_tables_from_expression(
        EXPRESSION => "expression",
        PROJECT    => "project_name"
    ),
    'GET TABLES FROM EXPRESSION "expression" IN PROJECT "project_name";',
    "get_tables_from_expression"
);
