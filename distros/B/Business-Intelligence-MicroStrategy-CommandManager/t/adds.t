#!perl -T

use Test::More;
use strict;
use warnings;

my $tests;

BEGIN {
    $tests = 27;
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib';
}

use Business::Intelligence::MicroStrategy::CommandManager;
my $foo = Business::Intelligence::MicroStrategy::CommandManager->new();

is(
    $foo->add_attribute_child(
        ATTRIBUTECHILD   => "Day",
        RELATIONSHIPTYPE => "ONETOMANY",
        ATTRIBUTE        => "Month",
        LOCATION         => "\\Schema Objects\\Attributes",
        PROJECT          => "MicroStrategy Tutorial"
    ),
'ADD ATTRIBUTECHILD "Day" RELATIONSHIPTYPE ONETOMANY TO ATTRIBUTE "Month" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";',
    "add_attribute_child"
);

is(
    $foo->add_attribute_form(
        ATTRIBUTEFORM => "Last Name",
        FORMDESC      => "Last Name Form",
        FORMCATEGORY  => "DESC",
        FORMTYPE      => "TEXT",
        SORT          => "DESC",
        EXPRESSION    => "[CUST_LAST_NAME]",
        LOOKUPTABLE   => "LU_CUSTOMER",
        ATTRIBUTE     => "Customer",
        LOCATION      => "\\Schema Objects\\Attributes",
        PROJECT       => "MicroStrategy Tutorial"
    ),
'ADD ATTRIBUTEFORM "Last Name" FORMDESC "Last Name Form" FORMCATEGORY "DESC" FORMTYPE TEXT SORT DESC EXPRESSION "[CUST_LAST_NAME]" LOOKUPTABLE "LU_CUSTOMER" TO ATTRIBUTE "Customer" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";',
    "add_attribute_form1"
);

is(
    $foo->add_attribute_form(
        ATTRIBUTEFORM   => "Last Name",
        FORMDESC        => "Last Name Form",
        FORMCATEGORY    => "DESC",
        FORMTYPE        => "TEXT",
        SORT            => "DESC",
        EXPRESSION      => "[CUST_LAST_NAME]",
        LOOKUPTABLE     => "LU_CUSTOMER",
        ATTRIBUTE       => "Customer",
        LOCATION        => "\\Schema Objects\\Attributes",
        PROJECT         => "MicroStrategy Tutorial",
        EXPSOURCETABLES => [ "MySourceTable1", "MySourceTable2" ],
    ),
'ADD ATTRIBUTEFORM "Last Name" FORMDESC "Last Name Form" FORMCATEGORY "DESC" FORMTYPE TEXT SORT DESC EXPRESSION "[CUST_LAST_NAME]" EXPSOURCETABLES "MySourceTable1", "MySourceTable2" LOOKUPTABLE "LU_CUSTOMER" TO ATTRIBUTE "Customer" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";',
    "add_attribute_form2"
);

is(
    $foo->add_attribute_form_expression(
        ATTRIBUTEFORMEXP => "ORDER_DATE",
        ATTRIBUTEFORM    => "ID",
        ATTRIBUTE        => "Day",
        LOCATION         => "\\Schema Objects\\Attributes",
        PROJECT          => "MicroStrategy Tutorial",
        EXPSOURCETABLES  => [ "MySourceTable1", "MySourceTable2" ],
        LOOKUPTABLE      => "LU_CUSTOMER",
        OVERWRITE        => "TRUE",
    ),
'ADD ATTRIBUTEFORMEXP "ORDER_DATE" EXPSOURCETABLES "MySourceTable1", "MySourceTable2" LOOKUPTABLE "LU_CUSTOMER" OVERWRITE TO ATTRIBUTEFORM "ID" FOR ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";',
    "add_attribute_form_expression1"
);

is(
    $foo->add_attribute_form_expression(
        ATTRIBUTEFORMEXP => "ORDER_DATE",
        ATTRIBUTEFORM    => "ID",
        ATTRIBUTE        => "Day",
        LOCATION         => "\\Schema Objects\\Attributes",
        PROJECT          => "MicroStrategy Tutorial"
    ),
'ADD ATTRIBUTEFORMEXP "ORDER_DATE" TO ATTRIBUTEFORM "ID" FOR ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";',
    "add_attribute_form_expression2"
);

is(
    $foo->add_attribute_form_expression(
        ATTRIBUTEFORMEXP => "ORDER_DATE",
        EXPSOURCETABLES  => [ "Mytable1", "Mytable2", ],
        LOOKUPTABLE      => "Lookup_table",
        ATTRIBUTEFORM    => "ID",
        ATTRIBUTE        => "Day",
        LOCATION         => "\\Schema Objects\\Attributes",
        PROJECT          => "MicroStrategy Tutorial"
    ),
'ADD ATTRIBUTEFORMEXP "ORDER_DATE" EXPSOURCETABLES "Mytable1", "Mytable2" LOOKUPTABLE "Lookup_table" TO ATTRIBUTEFORM "ID" FOR ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";',
    "add_attribute_form_expression3"
);

is(
    $foo->add_attribute_parent(
        ATTRIBUTEPARENT  => "Month of Year",
        RELATIONSHIPTYPE => "MANYTOONE",
        ATTRIBUTE        => "Month",
        LOCATION         => "\\Schema Objects\\Attributes",
        PROJECT          => "MicroStrategy Tutorial"
    ),
'ADD ATTRIBUTEPARENT "Month of Year" RELATIONSHIPTYPE MANYTOONE TO ATTRIBUTE "Month" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";',
    "add_attribute_parent"
);

is(
    $foo->add_configuration_ace(
        CONF_OBJECT_TYPE         => "SCHEDULE",
        OBJECT_NAME              => "All the time",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "FULLCONTROL"
    ),
'ADD ACE FOR SCHEDULE "All the time" USER "Developer" ACCESSRIGHTS FULLCONTROL;',
    "add_configuration_ace1"
);

is(
    $foo->add_configuration_ace(
        CONF_OBJECT_TYPE         => "SCHEDULE",
        OBJECT_NAME              => "All the time",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "DENIEDALL"
    ),
'ADD ACE FOR SCHEDULE "All the time" USER "Developer" ACCESSRIGHTS DENIEDALL;',
    "add_configuration_ace2"
);

is(
    $foo->add_configuration_ace(
        CONF_OBJECT_TYPE         => "GROUP",
        OBJECT_NAME              => "Developers",
        USER_OR_GROUP            => "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "Web Users",
        ACCESSRIGHTS             => "DENIEDALL"
    ),
    'ADD ACE FOR GROUP "Developers" GROUP "Web Users" ACCESSRIGHTS DENIEDALL;',
    "add_configuration_ace3"
);

is(
    $foo->add_configuration_ace(
        CONF_OBJECT_TYPE         => "SCHEDULE",
        OBJECT_NAME              => "All the time",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developers",
        ACCESSRIGHTS             => "CUSTOM",
        ACCESSRIGHTS_CUSTOM      => {
            BROWSE  => "GRANT",
            READ    => "GRANT",
            WRITE   => "GRANT",
            DELETE  => "DENY",
            CONTROL => "DENY",
            USE     => "DENY",
            EXECUTE => "DENY"
        }
    ),
'ADD ACE FOR SCHEDULE "All the time" USER "Developers" ACCESSRIGHTS CUSTOM GRANT BROWSE, READ, WRITE DENY CONTROL, DELETE, EXECUTE, USE;',
    "add_configuration_ace4"
);

is(
    $foo->add_custom_group_element(
        ELEMENT     => "25-35",
        EXPRESSION  => '([Customer Age]@ID Between 25.0 And 35.0)',
        CUSTOMGROUP => "Copy of Age Groups",
        LOCATION    => "\\Public Objects\\Custom Groups",
        PROJECT     => "MicroStrategy Tutorial"
    ),
'ADD ELEMENT "25-35" EXPRESSION "([Customer Age]@ID Between 25.0 And 35.0)" TO CUSTOMGROUP "Copy of Age Groups" IN FOLDER "\Public Objects\Custom Groups" FOR PROJECT "MicroStrategy Tutorial";',
    "add_custom_group_element1"
);

is(
    $foo->add_custom_group_element(
        ELEMENT         => "36-45",
        SHOWELEMENTNAME => "TRUE",
        EXPRESSION      => '([Customer Age]@ID Between 36.0 And 45.0)',
        BANDNAMES       => [ "Group1", "Group2" ],
        CUSTOMGROUP     => "Copy of Age Groups",
        LOCATION        => "\\Public Objects\\Custom Groups",
        PROJECT         => "MicroStrategy Tutorial"
    ),
'ADD ELEMENT "36-45" SHOWELEMENTNAME EXPRESSION "([Customer Age]@ID Between 36.0 And 45.0)" BANDNAMES "Group1", "Group2" TO CUSTOMGROUP "Copy of Age Groups" IN FOLDER "\Public Objects\Custom Groups" FOR PROJECT "MicroStrategy Tutorial";',
    "add_custom_group_element2"
);

is(
    $foo->add_custom_group_element(
        ELEMENT                     => "36-45",
        SHOWELEMENTNAME             => "TRUE",
        SHOWITEMSINELEMENT          => "TRUE",
        SHOWITEMSINELEMENTANDEXPAND => "TRUE",
        SHOWALLANDEXPAND            => "TRUE",
        EXPRESSION            => '([Customer Age]@ID Between 36.0 And 45.0)',
        BANDNAMES             => [ "Group1", "Group2" ],
        CUSTOMGROUP           => "Copy of Age Groups",
        LOCATION              => "\\Public Objects\\Custom Groups",
        PROJECT               => "MicroStrategy Tutorial",
        BREAKAMBIGUITY_FOLDER => '\Public Objects\Custom Groups\Customer',
        OUTPUTLEVEL           => [ "Customer Name", "Customer Address" ],
        OUTPUTLEVEL_LOCATIONS => ["\\Schema Objects\\Attributes\\Customer"]
    ),
'ADD ELEMENT "36-45" SHOWELEMENTNAME SHOWITEMSINELEMENT SHOWITEMSINELEMENTANDEXPAND SHOWALLANDEXPAND EXPRESSION "([Customer Age]@ID Between 36.0 And 45.0)" BREAKAMBIGUITY FOLDER "\Public Objects\Custom Groups\Customer" BANDNAMES "Group1", "Group2" OUTPUTLEVEL "Customer Name", "Customer Address" IN FOLDERS "\Schema Objects\Attributes\Customer" TO CUSTOMGROUP "Copy of Age Groups" IN FOLDER "\Public Objects\Custom Groups" FOR PROJECT "MicroStrategy Tutorial";',
    "add_custom_group_element3"
);

is(
    $foo->add_dbinstance(
        DBINSTANCE => "Extra Tutorial Data",
        PROJECT    => "MicroStrategy Tutorial"
    ),
    'ADD DBINSTANCE "Extra Tutorial Data" TO PROJECT "MicroStrategy Tutorial";',
    "add_dbinstance"
);

is(
    $foo->add_fact_expression(
        EXPRESSION =>
          '([QTY_SOLD] * (([UNIT_PRICE] - DISCOUNT) - [UNIT_COST]))',
        EXPSOURCETABLES => ["ORDER_DETAIL"],
        FACT            => "Profit",
        LOCATION        => "\\Public Objects",
        PROJECT         => "MicroStrategy Tutorial"
    ),
'ADD EXPRESSION "([QTY_SOLD] * (([UNIT_PRICE] - DISCOUNT) - [UNIT_COST]))" EXPSOURCETABLES "ORDER_DETAIL" TO FACT "Profit" IN FOLDER "\Public Objects" FOR PROJECT "MicroStrategy Tutorial";',
    "add_fact_expression1"
);

is(
    $foo->add_fact_expression(
        EXPRESSION      => 'ORDER_ID',
        EXPSOURCETABLES => ["RUSH_ORDER"],
        OVERWRITE       => "TRUE",
        FACT            => "Profit",
        LOCATION        => "\\Public Objects",
        PROJECT         => "MicroStrategy Tutorial"
    ),
'ADD EXPRESSION "ORDER_ID" EXPSOURCETABLES "RUSH_ORDER" OVERWRITE TO FACT "Profit" IN FOLDER "\Public Objects" FOR PROJECT "MicroStrategy Tutorial";',
    "add_fact_expression2"
);

is(
    $foo->add_folder_ace(
        FOLDER                   => "Subtotals",
        LOCATION                 => "\\Project Objects",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "FULLCONTROL",
        CHILDRENACCESSRIGHTS     => "MODIFY",
        PROJECT                  => "MicroStrategy Tutorial"
    ),
'ADD ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "Developer" ACCESSRIGHTS FULLCONTROL CHILDRENACCESSRIGHTS MODIFY FOR PROJECT "MicroStrategy Tutorial";',
    "add_folder_ace1"
);

is(
    $foo->add_folder_ace(
        FOLDER                   => "Subtotals",
        LOCATION                 => "\\Project Objects",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "CUSTOM",
        ACCESSRIGHTS_CUSTOM      => {
            BROWSE  => "GRANT",
            READ    => "GRANT",
            WRITE   => "GRANT",
            DELETE  => "GRANT",
            CONTROL => "DENY",
            USE     => "DENY",
            EXECUTE => "DENY"
        },
        CHILDRENACCESSRIGHTS => "MODIFY",
        PROJECT              => "MicroStrategy Tutorial"
    ),
'ADD ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "Developer" ACCESSRIGHTS CUSTOM GRANT BROWSE, DELETE, READ, WRITE DENY CONTROL, EXECUTE, USE CHILDRENACCESSRIGHTS MODIFY FOR PROJECT "MicroStrategy Tutorial";',
    "add_folder_ace2"
);

is(
    $foo->add_folder_ace(
        FOLDER                   => "Subtotals",
        LOCATION                 => "\\Project Objects",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "CUSTOM",
        ACCESSRIGHTS_CUSTOM      => {
            BROWSE  => "GRANT",
            READ    => "GRANT",
            WRITE   => "GRANT",
            DELETE  => "DENY",
            CONTROL => "DENY",
            USE     => "DENY",
            EXECUTE => "DENY"
        },
        CHILDRENACCESSRIGHTS => "FULLCONTROL",
        PROJECT              => "MicroStrategy Tutorial"
    ),
'ADD ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "Developer" ACCESSRIGHTS CUSTOM GRANT BROWSE, READ, WRITE DENY CONTROL, DELETE, EXECUTE, USE CHILDRENACCESSRIGHTS FULLCONTROL FOR PROJECT "MicroStrategy Tutorial";',
    "add_folder_ace3"
);

is(
    $foo->add_folder_ace(
        FOLDER                      => "Subtotals",
        LOCATION                    => "\\Project Objects",
        USER_OR_GROUP               => "USER",
        USER_LOGIN_OR_GROUP_NAME    => "Developer",
        ACCESSRIGHTS                => "MODIFY",
        CHILDRENACCESSRIGHTS        => "CUSTOM",
        CHILDRENACCESSRIGHTS_CUSTOM => {
            BROWSE  => "GRANT",
            READ    => "GRANT",
            WRITE   => "GRANT",
            DELETE  => "DENY",
            CONTROL => "DENY",
            USE     => "DENY",
            EXECUTE => "DENY"
        },
        PROJECT => "MicroStrategy Tutorial"
    ),
'ADD ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "Developer" ACCESSRIGHTS MODIFY CHILDRENACCESSRIGHTS CUSTOM GRANT BROWSE, READ, WRITE DENY CONTROL, DELETE, EXECUTE, USE FOR PROJECT "MicroStrategy Tutorial";',
    "add_folder_ace4"
);

is(
    $foo->add_folder_ace(
        FOLDER                   => "Subtotals",
        LOCATION                 => "\\Project Objects",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "CUSTOM",
        ACCESSRIGHTS_CUSTOM      => {
            BROWSE  => "GRANT",
            READ    => "GRANT",
            WRITE   => "GRANT",
            DELETE  => "DENY",
            CONTROL => "DENY",
            USE     => "DENY",
            EXECUTE => "DENY"
        },
        CHILDRENACCESSRIGHTS        => "CUSTOM",
        CHILDRENACCESSRIGHTS_CUSTOM => {
            BROWSE  => "DENY",
            READ    => "DENY",
            WRITE   => "DENY",
            DELETE  => "GRANT",
            CONTROL => "GRANT",
            USE     => "GRANT",
            EXECUTE => "GRANT"
        },
        PROJECT => "MicroStrategy Tutorial"
    ),
'ADD ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "Developer" ACCESSRIGHTS CUSTOM GRANT BROWSE, READ, WRITE DENY CONTROL, DELETE, EXECUTE, USE CHILDRENACCESSRIGHTS CUSTOM GRANT CONTROL, DELETE, EXECUTE, USE DENY BROWSE, READ, WRITE FOR PROJECT "MicroStrategy Tutorial";',
    "add_folder_ace5"
);

is(
    $foo->add_project_ace(
        PROJECT_OBJECT_TYPE      => "FACT",
        OBJECT_NAME              => "MyFact",
        LOCATION                 => "\\Schema Objects\\Facts",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "VIEW",
        PROJECT                  => "MicroStrategy Tutorial"
    ),
'ADD ACE FOR FACT "MyFact" IN FOLDER "\\Schema Objects\\Facts" USER "Developer" ACCESSRIGHTS VIEW FOR PROJECT "MicroStrategy Tutorial";',
    "add_project_ace"
);

is(
    $foo->add_server_cluster( SERVER => "PROD_SRV" ),
    'ADD SERVER "PROD_SRV" TO CLUSTER;',
    "add_server_cluster"
);

is( $foo->add_user( USER => "palcazar", GROUP => ["Managers"] ),
    'ADD USER "palcazar" TO GROUP "Managers";', "add_user" );

is(
    $foo->add_whtable(
        WHTABLE             => "DT_QUARTER",
        PREFIX              => "Tutorial",
        AUTOMAPPING         => "TRUE",
        CALTABLELOGICALSIZE => "TRUE",
        COLMERGEOPTION      => "MAXDENOMINATOR",
        PROJECT             => "MicroStrategy Tutorial"
    ),
'ADD WHTABLE "DT_QUARTER" PREFIX "Tutorial" AUTOMAPPING TRUE CALTABLELOGICALSIZE TRUE COLMERGEOPTION MAXDENOMINATOR TO PROJECT "MicroStrategy Tutorial";',
    "add_whtable1"
);

is(
    $foo->add_whtable(
        WHTABLE        => "DT_YEAR",
        COLMERGEOPTION => "MAXDENOMINATOR",
        PROJECT        => "MicroStrategy Tutorial"
    ),
'ADD WHTABLE "DT_YEAR" COLMERGEOPTION MAXDENOMINATOR TO PROJECT "MicroStrategy Tutorial";',
    "add_whtable2"
);
