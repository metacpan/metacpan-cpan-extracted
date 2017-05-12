#!perl -T

use Test::More;
use strict;
use warnings;

my $tests;

BEGIN {
    $tests = 22;
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib';
}

use Business::Intelligence::MicroStrategy::CommandManager;
my $foo = Business::Intelligence::MicroStrategy::CommandManager->new();

is(
    $foo->create_attribute(
        ATTRIBUTE     => "Day",
        DESCRIPTION   => 'Duplicate of Day Attribute from folder \Time',
        LOCATION      => '\Schema Objects\Attributes',
        ATTRIBUTEFORM => "ID",
        FORMDESC      => "Basic ID form",
        FORMTYPE      => "TEXT",
        SORT          => "ASC",
        EXPRESSION    => "[DAY_DATE]",
        LOOKUPTABLE   => "LU_DAY",
        PROJECT       => "MicroStrategy Tutorial"
    ),
'CREATE ATTRIBUTE "Day" DESCRIPTION "Duplicate of Day Attribute from folder \Time" IN FOLDER "\Schema Objects\Attributes" ATTRIBUTEFORM "ID" FORMDESC "Basic ID form" FORMTYPE TEXT SORT ASC EXPRESSION "[DAY_DATE]" LOOKUPTABLE "LU_DAY" FOR PROJECT "MicroStrategy Tutorial";',
    "create_attribute"
);

is(
    $foo->create_connection_map(
        USER         => "login_name",
        DBINSTANCE   => "dbinstance_name",
        DBCONNECTION => "dbConnection_name",
        DBLOGIN      => "dblogin_name",
        PROJECT      => "project_name"
    ),
'CREATE CONNECTION MAP FOR USER "login_name" DBINSTANCE "dbinstance_name" DBCONNECTION "dbConnection_name" DBLOGIN "dblogin_name" ON PROJECT "project_name";',
    "create_connection_map"
);

is(
    $foo->create_custom_group(
        CUSTOMGROUP                 => "customgroup_name",
        DESCRIPTION                 => "description",
        ENABLEHIERARCHICALDISPLAY   => "TRUE",
        ENABLESUBTOTALDISPLAY       => "TRUE",
        ELEMENTHEADERPOSITION       => "BELOW",
        HIDDEN                      => "TRUE",
        ELEMENT                     => "element_name",
        SHOWELEMENTNAME             => "TRUE",
        SHOWITEMSINELEMENT          => "TRUE",
        SHOWITEMSINELEMENTANDEXPAND => "TRUE",
        SHOWALLANDEXPAND            => "TRUE",
        EXPRESSION                  => "expression",
        BREAKAMBIGUITY_FOLDER       => "local_symbol_folder",
        BANDNAMES                   => [ "name1", "nameN" ],
        OUTPUTLEVEL                 => [ "attribute_name1", "attributenameN" ],
        OUTPUTLEVEL_LOCATIONS =>
          [ "outputlevel_location_path1", "outputlevel_location_pathN" ],
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'CREATE CUSTOMGROUP "customgroup_name" DESCRIPTION "description" ENABLEHIERARCHICALDISPLAY TRUE ENABLESUBTOTALDISPLAY TRUE ELEMENTHEADERPOSITION BELOW HIDDEN TRUE ELEMENT "element_name" SHOWELEMENTNAME SHOWITEMSINELEMENT SHOWITEMSINELEMENTANDEXPAND SHOWALLANDEXPAND EXPRESSION "expression" BREAKAMBIGUITY FOLDER "local_symbol_folder" BANDNAMES "name1", "nameN" OUTPUTLEVEL "attribute_name1", "attributenameN" IN FOLDERS "outputlevel_location_path1", "outputlevel_location_pathN" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "create_custom_group"
);

is(
    $foo->create_dbconnection(
        DBCONNECTION     => "dbconnection_name",
        ODBCDSN          => "odbc_datasource_name",
        DEFAULTLOGIN     => "default_login",
        DRIVERMODE       => "MULTIPROCESS",
        EXECMODE         => "SYNCHRONOUS",
        USEEXTENDEDFETCH => "TRUE",
        USEPARAMQUERIES  => "TRUE",
        MAXCANCELATTEMPT => "number_of_seconds",
        MAXQUERYEXEC     => "number_of_seconds",
        MAXCONNATTEMPT   => "number_of_seconds",
        CHARSETENCODING  => "MULTIBYTE",
        TIMEOUT          => "number_of_seconds",
        IDLETIMEOUT      => "number_of_seconds"
    ),
'CREATE DBCONNECTION "dbconnection_name" ODBCDSN "odbc_datasource_name" DEFAULTLOGIN "default_login" DRIVERMODE MULTIPROCESS EXECMODE SYNCHRONOUS USEEXTENDEDFETCH TRUE USEPARAMQUERIES TRUE MAXCANCELATTEMPT number_of_seconds MAXQUERYEXEC number_of_seconds MAXCONNATTEMPT number_of_seconds CHARSETENCODING MULTIBYTE TIMEOUT number_of_seconds IDLETIMEOUT number_of_seconds;',
    "create_dbconnection"
);

is(
    $foo->create_dbinstance(
        DBINSTANCE        => "dbinstance_name",
        DBCONNTYPE        => "dbconnection_type",
        DBCONNECTION      => "dbconnection_name",
        DESCRIPTION       => "description",
        DATABASE          => "database_name",
        TABLESPACE        => "tablespace_name",
        PRIMARYDBINSTANCE => "dbinstance_name",
        DATAMART          => "dbinstance_name",
        TABLEPREFIX       => "table_prefix",
        HIGHTHREADS       => "no_high_conns",
        MEDIUMTHREADS     => "no_medium_conns",
        LOWTHREADS        => "no_low_conns"
    ),
'CREATE DBINSTANCE "dbinstance_name" DBCONNTYPE "dbconnection_type" DBCONNECTION "dbconnection_name" DESCRIPTION "description" DATABASE "database_name" TABLESPACE "tablespace_name" PRIMARYDBINSTANCE "dbinstance_name" DATAMART "dbinstance_name" TABLEPREFIX "table_prefix" HIGHTHREADS no_high_conns MEDIUMTHREADS no_medium_conns LOWTHREADS no_low_conns;',
    "create_dbinstance"
);

is(
    $foo->create_dblogin(
        DBLOGIN  => "dblogin_name",
        LOGIN    => "database_login",
        PASSWORD => "database_pwd"
    ),
'CREATE DBLOGIN "dblogin_name" LOGIN "database_login" PASSWORD "database_pwd";',
    "create_dblogin"
);

is(
    $foo->create_event(
        EVENT       => "event_name",
        DESCRIPTION => "description"
    ),
    'CREATE EVENT "event_name" DESCRIPTION "description";',
    "create_event"
);

is(
    $foo->create_fact(
        FACT            => "fact_name",
        DESCRIPTION     => "description",
        LOCATION        => "location_path",
        HIDDEN          => "TRUE",
        EXPRESSION      => "expression",
        EXPSOURCETABLES => [ "sourcetable1", "sourcetableN" ],
        PROJECT         => "project_name"
    ),
'CREATE FACT "fact_name" DESCRIPTION "description" IN FOLDER "location_path" HIDDEN TRUE EXPRESSION "expression" EXPSOURCETABLES "sourcetable1", "sourcetableN" FOR PROJECT "project_name";',
    "create_fact"
);

is(
    $foo->create_filter_oultine(
        FILTER      => "filter_name",
        LOCATION    => "location_path",
        EXPRESSION  => "expression",
        DESCRIPTION => "description",
        HIDDEN      => "TRUE",
        PROJECT     => "project_name"
    ),
'CREATE FILTER "filter_name" IN FOLDER "location_path" EXPRESSION "expression" DESCRIPTION "description" HIDDEN TRUE ON PROJECT "project_name";',
    "create_filter_oultine"
);

is(
    $foo->create_folder(
        FOLDER      => "folder_name",
        LOCATION    => "location_path",
        DESCRIPTION => "description",
        HIDDEN      => "TRUE",
        PROJECT     => "project_name"
    ),
'CREATE FOLDER "folder_name" IN "location_path" DESCRIPTION "description" HIDDEN TRUE FOR PROJECT "project_name";',
    "create_folder"
);

is(
    $foo->create_metric_oultine(
        METRIC      => "metric_name",
        LOCATION    => "location_path",
        EXPRESSION  => "expression",
        DESCRIPTION => "description",
        HIDDEN      => "TRUE",
        PROJECT     => "project_name"
    ),
'CREATE METRIC "metric_name" IN FOLDER "location_path" EXPRESSION "expression" DESCRIPTION "description" HIDDEN TRUE ON PROJECT "project_name";',
    "create_metric_oultine"
);

is(
    $foo->create_schedule(
        SCHEDULE            => "Schedule9",
        STARTDATE           => "09/10/2002",
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        YEARLY              => "SECOND SATURDAY OF MAY",
        EXECUTE_TIME_OF_DAY => "09:00",
    ),
'CREATE SCHEDULE "Schedule9" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED YEARLY SECOND SATURDAY OF MAY EXECUTE 09:00;',
    "create_schedule"
);

is(
    $foo->create_schedule_relation(
        SCHEDULE                 => "Schedule1",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "jen",
        REPORT                   => "rep_or_doc_name",
        LOCATION                 => "location_path",
        PROJECT                  => "project_name",
        CREATEMSGHIST            => "TRUE",
        ENABLEMOBILEDELIVERY     => "TRUE",
        OVERWRITE                => "TRUE",
        UPDATECACHE              => "TRUE",
    ),
'CREATE SCHEDULERELATION SCHEDULE "Schedule1" USER "jen" REPORT "rep_or_doc_name" IN "location_path" IN PROJECT "project_name" CREATEMSGHIST TRUE ENABLEMOBILEDELIVERY OVERWRITE UPDATECACHE;',
    "create_schedule_relation"
);

is(
    $foo->create_security_filter(
        SECURITY_FILTER       => "sec_filter_name",
        LOCATION              => "location_path",
        HIDDEN                => "TRUE",
        PROJECT               => "project_name",
        FILTER                => "filter_name",
        FILTER_LOCATION       => "filter_location_path",
        EXPRESSION            => "expression",
        TOP_ATTRIBUTE_LIST    => [ "top_attr_name1", "top_attr_nameN" ],
        BOTTOM_ATTRIBUTE_LIST => [ "bottom_attr_name1", "bottom_attr_nameN" ]
    ),
'CREATE SECURITY FILTER "sec_filter_name" FOLDER "location_path" HIDDEN TRUE IN PROJECT "project_name" FILTER "filter_name" IN FOLDER "filter_location_path" EXPRESSION "expression" TOP ATTRIBUTE LIST "top_attr_name1", "top_attr_nameN" BOTTOM ATTRIBUTE LIST "bottom_attr_name1", "bottom_attr_nameN";',
    "create_security_filter"
);

is(
    $foo->create_security_role(
        SECURITY_ROLE => "sec_role_name",
        DESCRIPTION   => "sec_role_description"
    ),
    'CREATE SECURITY ROLE "sec_role_name" DESCRIPTION "sec_role_description";',
    "create_security_role"
);

=head2 shortcuts

CREATE SHORTCUT IN FOLDER "\Public Objects"  FOR METRIC "Revenue" IN FOLDER "\Public Objects\Metrics\Sales Metrics" FOR PROJECT "MicroStrategy Tutorial";

CREATE SHORTCUT IN FOLDER "\Public Objects"  FOR DOCUMENT "Shipping Analysis" IN FOLDER "\Public Objects\Reports\Enterprise Reporting Documents" FOR PROJECT  "MicroStrategy Tutorial";

CREATE SHORTCUT IN FOLDER "\Public Objects" FOR ATTRIBUTE "Customer" IN FOLDER "\Schema Objects\Attributes\Customers" FOR PROJECT "Microstrategy Tutorial";

CREATE SHORTCUT IN FOLDER "\Public Objects" FOR FACT "Profit" IN FOLDER "\Schema Objects\Facts\" FOR PROJECT "MicroStrategy Tutorial";

CREATE SHORTCUT IN FOLDER "\Public Objects" FOR HIERARCHY "Time (Browsing)" IN FOLDER "\Schema Objects\Hierarchies\Data Explorer" FOR PROJECT "MicroStrategy Tutorial";

CREATE SHORTCUT IN FOLDER "\Public Objects" FOR TABLE "PMT_INVENTORY" IN FOLDER "\Schema Objects\Partition Mappings" FOR PROJECT "MicroStrategy Tutorial";

CREATE SHORTCUT IN FOLDER "\Public Objects" FOR SECFILTER "NewSecurity Filter1" IN FOLDER "\Project Objects\MD Security Filters" FOR PROJECT "MicroStrategy Tutorial";

CREATE SHORTCUT IN FOLDER "\Public Objects" FOR FILTER "Age Groups" IN FOLDER "\Public Objects\Custom Groups" FOR PROJECT "MicroStrategy Tutorial";

CREATE SHORTCUT IN FOLDER "\Public Objects" FOR FILTER "Eastern United States Customers" IN FOLDER "\Public Objects\Filters\Customer Analysis FIlters" FOR PROJECT "MicroStrategy Tutorial";

CREATE SHORTCUT IN FOLDER "\Public Objects" FOR FOLDER "Drill Maps" IN FOLDER "\Public Objects" FOR PROJECT "MicroStrategy Tutorial";

CREATE SHORTCUT IN FOLDER "\Public Objects" FOR FOLDER "Drill Maps" IN FOLDER "\Public Objects" HIDDEN TRUE FOR PROJECT "MicroStrategy Tutorial";

=cut

is(
    $foo->create_shortcut(
        LOCATION              => "location_path",
        PROJECT_CONFIG_OBJECT => "FOLDER",
        NAME                  => "object_name",
        OBJECT_LOCATION       => "object_location_path",
        HIDDEN                => "FALSE",
        PROJECT               => "project_name"
    ),
'CREATE SHORTCUT IN FOLDER "location_path" FOR FOLDER "object_name" IN FOLDER "object_location_path" HIDDEN FALSE FOR PROJECT "project_name";',
    "create_shortcut"
);

is(
    $foo->create_user(
        USER            => "login_name",
        NTLINK          => "nt_user_id",
        PASSWORD        => "user_password",
        FULLNAME        => "user_fullname",
        DESCRIPTION     => "user_description",
        LDAPLINK        => "ldap_user_id",
        WHLINK          => "warehouse_login",
        WHPASSWORD      => "warehouse_password",
        ALLOWCHANGEPWD  => "TRUE",
        ALLOWSTDAUTH    => "TRUE",
        CHANGEPWD       => "TRUE",
        PASSWORDEXP     => "NEVER",
        PASSWORDEXPFREQ => "60 DAYS",
        ENABLED         => "ENABLED",
        GROUP           => "user_group_name"
    ),
'CREATE USER "login_name" NTLINK "nt_user_id" PASSWORD "user_password" FULLNAME "user_fullname" DESCRIPTION "user_description" LDAPLINK "ldap_user_id" WHLINK "warehouse_login" WHPASSWORD "warehouse_password" ALLOWCHANGEPWD TRUE ALLOWSTDAUTH TRUE CHANGEPWD TRUE PASSWORDEXP NEVER PASSWORDEXPFREQ 60 DAYS ENABLED IN GROUP "user_group_name";',
    "create_user1"
);

is(
    $foo->create_user(
        USER        => "dsmith",
        PASSWORD    => "iHydAA",
        FULLNAME    => "Daniel Smith",
        PASSWORDEXP => "NEVER",
    ),
'CREATE USER "dsmith" PASSWORD "iHydAA" FULLNAME "Daniel Smith" PASSWORDEXP NEVER;',
    "create_user2"
);

is(
    $foo->create_user(
        USER           => "fquintz",
        PASSWORD       => "fg56Mx",
        FULLNAME       => "Frank Quintz",
        ALLOWCHANGEPWD => "TRUE",
    ),
'CREATE USER "fquintz" PASSWORD "fg56Mx" FULLNAME "Frank Quintz" ALLOWCHANGEPWD TRUE;',
    "create_user3"
);

is(
    $foo->create_user(
        USER          => '\DomainName\UserName',
        IMPORTWINUSER => "TRUE",
    ),
    'CREATE USER IMPORTWINUSER "\DomainName\UserName";',
    "create_user4"
);

is(
    $foo->create_user_group(
        USER_GROUP   => "user_group_name",
        DESCRIPTION  => "user_group_desc",
        LDAPLINK     => "ldap_user_id",
        MEMBERS      => [ "login_name1", "login_nameN" ],
        PARENT_GROUP => "parent_user_group_name"
    ),
'CREATE USER GROUP "user_group_name" DESCRIPTION "user_group_desc" LDAPLINK "ldap_user_id" MEMBERS "login_name1", "login_nameN" GROUP "parent_user_group_name";',
    "create_user_group"
);

is(
    $foo->create_user_profile(
        USER     => "login_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'CREATE USER PROFILE FOR USER "login_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "create_user_profile"
);

