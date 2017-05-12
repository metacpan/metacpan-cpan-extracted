#!perl -T

use Test::More;
use strict;
use warnings;

my $tests;

BEGIN {
    $tests = 13;
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib';
}

use Business::Intelligence::MicroStrategy::CommandManager;
my $foo = Business::Intelligence::MicroStrategy::CommandManager->new();

is(
    $foo->remove_attribute_child(
        ATTRIBUTECHILD => "attributechild_name",
        ATTRIBUTE      => "attribute_name",
        LOCATION       => "location_path",
        PROJECT        => "project_name"
    ),
'REMOVE ATTRIBUTECHILD "attributechild_name" FROM ATTRIBUTE "attribute_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "remove_attribute_child"
);

is(
    $foo->remove_attribute_form_expression(
        ATTRIBUTEFORMEXP => "expression",
        ATTRIBUTEFORM    => "form_name",
        ATTRIBUTE        => "attribute_name",
        LOCATION         => "location_path",
        PROJECT          => "project_name"
    ),
'REMOVE ATTRIBUTEFORMEXP "expression" FROM ATTRIBUTEFORM "form_name" FOR ATTRIBUTE "attribute_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "remove_attribute_form_expression"
);

is(
    $foo->remove_attribute_form(
        ATTRIBUTEFORM => "form_name",
        ATTRIBUTE     => "attribute_name",
        LOCATION      => "location_path",
        PROJECT       => "project_name"
    ),
'REMOVE ATTRIBUTEFORM "form_name" FROM ATTRIBUTE "attribute_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "remove_attribute_form"
);

is(
    $foo->remove_attribute_parent(
        ATTRIBUTEPARENT => "attributeparent_name",
        ATTRIBUTE       => "attribute_name",
        LOCATION        => "location_path",
        PROJECT         => "project_name"
    ),
'REMOVE ATTRIBUTEPARENT "attributeparent_name" FROM ATTRIBUTE "attribute_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "remove_attribute_parent"
);

is(
    $foo->remove_configuration_ace(
        CONF_OBJECT_TYPE         => "conf_object_type",
        OBJECT_NAME              => "object_name",
        USER_OR_GROUP            => "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name"
    ),
'REMOVE ACE FROM conf_object_type "object_name" GROUP "user_login_or_group_name";',
    "remove_configuration_ace"
);

is(
    $foo->remove_custom_group_element(
        ELEMENT     => "element_name",
        CUSTOMGROUP => "customgroup_name",
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    ),
'REMOVE ELEMENT "element_name" FROM CUSTOMGROUP "customgroup_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "remove_custom_group_element"
);

is(
    $foo->remove_dbinstance(
        DBINSTANCE => "DBInstance_name",
        PROJECT    => "project_name"
    ),
    'REMOVE DBINSTANCE "DBInstance_name" FROM PROJECT "project_name";',
    "remove_dbinstance"
);

is(
    $foo->remove_fact_expression(
        EXPRESSION => "expression",
        FACT       => "fact_name",
        LOCATION   => "location_path",
        PROJECT    => "project_name"
    ),
'REMOVE EXPRESSION "expression" FROM FACT "fact_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "remove_fact_expression"
);

is(
    $foo->remove_folder_ace(
        FOLDER                   => "folder_name",
        LOCATION                 => "location_path",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        PROJECT                  => "project_name"
    ),
'REMOVE ACE FROM FOLDER "folder_name" IN FOLDER "location_path" USER "user_login_or_group_name" FOR PROJECT "project_name";',
    "remove_folder_ace"
);

is(
    $foo->remove_project_ace(
        PROJECT_OBJECT_TYPE      => "project_object_type",
        OBJECT_NAME              => "object_name",
        LOCATION                 => "location_path",
        USER_OR_GROUP            => "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        PROJECT                  => "project_name"
    ),
'REMOVE ACE FROM project_object_type "object_name" IN FOLDER "location_path" GROUP "user_login_or_group_name" FOR PROJECT "project_name";',
    "remove_project_ace"
);

is(
    $foo->remove_server_cluster("server_name"),
    'REMOVE SERVER "server_name" FROM CLUSTER;',
    "remove_server_cluster"
);

is(
    $foo->remove_user(
        USER  => "login_name",
        GROUP => [ "group_name1", "group_nameN" ]
    ),
    'REMOVE USER "login_name" FROM GROUP "group_name1", "group_nameN";',
    "remove_user"
);

is(
    $foo->remove_whtable(
        WHTABLE => "warehouse_table_name",
        PROJECT => "project_name"
    ),
    'REMOVE WHTABLE "warehouse_table_name" FROM PROJECT "project_name";',
    "remove_whtable"
);
