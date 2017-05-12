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
    $foo->delete_attribute(
        ATTRIBUTE => "attribute_name",
        LOCATION  => "location_path",
        PROJECT   => "project_name"
    ),
'DELETE ATTRIBUTE "attribute_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "delete_attribute"
);
is(
    $foo->delete_connection_map(
        USER       => "login_name",
        DBINSTANCE => "dbinstance_name",
        PROJECT    => "project_name"
    ),
'DELETE CONNECTION MAP FOR USER "login_name" DBINSTANCE "dbinstance_name" ON PROJECT "project_name";',
    "delete_connection_map"
);
is(
    $foo->delete_custom_group(
        CUSTOMGROUP => "customgroup_name",
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    ),
'DELETE CUSTOMGROUP "customgroup_name" IN FOLDER "location_path" FROM PROJECT "project_name";',
    "delete_custom_group"
);
is(
    $foo->delete_dbconnection( DBCONNECTION => "dbConnection_name" ),
    'DELETE DBCONNECTION "dbConnection_name";',
    "delete_dbconnection"
);
is(
    $foo->delete_dbinstance( DBINSTANCE => "dbinstance_name" ),
    'DELETE DBINSTANCE "dbinstance_name";',
    "delete_dbinstance"
);
is(
    $foo->delete_dblogin( DBLOGIN => "dblogin_name" ),
    'DELETE DBLOGIN "dblogin_name";',
    "delete_dblogin"
);
is(
    $foo->delete_event( EVENT => "event_name" ),
    'DELETE EVENT "event_name";',
    "delete_event"
);
is(
    $foo->delete_fact(
        FACT     => "fact_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'DELETE FACT "fact_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "delete_fact"
);
is(
    $foo->delete_filter(
        FILTER   => "filter_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'DELETE FILTER "filter_name" IN FOLDER "location_path" FROM PROJECT "project_name";',
    "delete_filter"
);
is(
    $foo->delete_folder(
        FOLDER   => "folder_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'DELETE FOLDER "folder_name" IN "location_path" FROM PROJECT "project_name";',
    "delete_folder"
);
is(
    $foo->delete_metric(
        METRIC   => "metric_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'DELETE METRIC "metric_name" IN FOLDER "location_path" FROM PROJECT "project_name";',
    "delete_metric"
);
is(
    $foo->delete_project("project_name"),
    'DELETE PROJECT "project_name";',
    "delete_project"
);
is(
    $foo->delete_report(
        REPORT   => "report_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'DELETE REPORT "report_name" IN FOLDER "location_path" FROM PROJECT "project_name";',
    "delete_report"
);

is(
    $foo->delete_report_cache(
        INVALID      => "TRUE",
        REPORT_CACHE => "ALL",
        PROJECT      => [ "project_name1", "project_nameN" ],
    ),
'DELETE ALL INVALID REPORT CACHES IN PROJECTS "project_name1", "project_nameN";',
    "delete_report_cache"
);

is(
    $foo->delete_schedule("schedule_name"),
    'DELETE SCHEDULE "schedule_name";',
    "delete_schedule"
);

is(
    $foo->delete_schedule_relation(
        DELETE_MULTIPLE => "TRUE",
        REPORT          => "Revenue vs. Forecast",
        LOCATION =>
'\Public Objects\Reports\Subject Areas\Sales and Profitability Analysis',
        PROJECT => "MicroStrategy Tutorial"
    ),
'DELETE ALL SCHEDULERELATIONS FOR REPORT "Revenue vs. Forecast" IN "\Public Objects\Reports\Subject Areas\Sales and Profitability Analysis" FROM PROJECT "MicroStrategy Tutorial";',
    "delete_schedule_relation1"
);

is(
    $foo->delete_schedule_relation(
        DELETE_MULTIPLE          => "TRUE",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "crosie",
        PROJECT                  => "MicroStrategy Tutorial"
    ),
'DELETE ALL SCHEDULERELATIONS FOR USER "crosie" FROM PROJECT "MicroStrategy Tutorial";',
    "delete_schedule_relation2"
);

is(
    $foo->delete_schedule_relation(
        DELETE_MULTIPLE => "TRUE",
        SCHEDULE        => "All The Time",
        PROJECT         => "MicroStrategy Tutorial"
    ),
'DELETE ALL SCHEDULERELATIONS FOR SCHEDULE "All The Time" FROM PROJECT "MicroStrategy Tutorial";',
    "delete_schedule_relation3"
);

is(
    $foo->delete_schedule_relation(
        DELETE_MULTIPLE => "TRUE",
        PROJECT         => "MicroStrategy Tutorial"
    ),
    'DELETE ALL SCHEDULERELATIONS FROM PROJECT "MicroStrategy Tutorial";',
    "delete_schedule_relation4"
);

is(
    $foo->delete_schedule_relation(
        DELETE_MULTIPLE          => "FALSE",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "crosie",
        SCHEDULE                 => "All The Time",
        REPORT                   => "rep_or_doc_name",
        LOCATION                 => "location_path",
        PROJECT                  => "project_name"
    ),
'DELETE SCHEDULERELATION SCHEDULE "All The Time" USER "crosie" REPORT "rep_or_doc_name" IN "location_path" FROM PROJECT "project_name";',
    "delete_schedule_relation5"
);

is(
    $foo->delete_security_filter(
        SECURITY_FILTER => "sec_filter_name",
        LOCATION        => "location_path",
        PROJECT         => "project_name"
    ),
'DELETE SECURITY FILTER "sec_filter_name" FOLDER "location_path" FROM PROJECT "project_name";',
    "delete_security_filter"
);

is(
    $foo->delete_security_role("sec_role_name"),
    'DELETE SECURITY ROLE "sec_role_name";',
    "delete_security_role"
);

is(
    $foo->delete_shortcut(
        LOCATION              => "location_path",
        PROJECT_CONFIG_OBJECT => "FOLDER",
        NAME                  => "shortcut_name",
        PROJECT               => "project_name"
    ),
'DELETE SHORTCUT IN FOLDER "location_path" FOR FOLDER "shortcut_name" FOR PROJECT "project_name";',
    "delete_shortcut"
);

is(
    $foo->delete_user(
        USER    => "login_name",
        CASCADE => "TRUE"
    ),
    'DELETE USER "login_name" CASCADE PROFILES;',
    "delete_user1"
);

is(
    $foo->delete_user( USER => "login_name" ),
    'DELETE USER "login_name";',
    "delete_user2"
);

is(
    $foo->delete_user_group("user_group"),
    'DELETE USER GROUP "user_group";',
    "delete_user_group"
);
is(
    $foo->delete_user_profile(
        USER_PROFILE => "login_name",
        PROJECT      => "project_name"
    ),
    'DELETE USER PROFILE "login_name" FROM PROJECT "project_name";',
    "delete_user_profile"
);
