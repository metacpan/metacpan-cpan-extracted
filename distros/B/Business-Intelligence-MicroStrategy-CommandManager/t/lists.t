#!perl -T

use Test::More;
use strict;
use warnings;

my $tests;

BEGIN {
    $tests = 76;
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib';
}

use Business::Intelligence::MicroStrategy::CommandManager;
my $foo = Business::Intelligence::MicroStrategy::CommandManager->new();

is(
    $foo->list_acl_properties(
        OBJECT_TYPE => "FOLDER",
        OBJECT_NAME => "folder_name",
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    ),
'LIST ALL PROPERTIES FOR ACL FROM FOLDER "folder_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "list_acl_properties"
);

is(
    $foo->list_all_connection_maps("project_name"),
    'LIST ALL CONNECTION MAP FOR PROJECT "project_name";',
    "list_all_connection_maps"
);

is(
    $foo->list_all_dbconnections,
    'LIST ALL DBCONNECTIONS;',
    "list_all_dbconnections"
);

is( $foo->list_all_dbinstances, 'LIST ALL DBINSTANCES;',
    "list_all_dbinstances" );

is( $foo->list_all_dblogins, 'LIST ALL DBLOGINS;', "list_all_dblogins" );

is( $foo->list_all_servers, 'LIST ALL SERVERS;', "list_all_servers" );

is(
    $foo->list_attribute_properties(
        ATTRIBUTE => "attribute_name",
        LOCATION  => "location_path",
        PROJECT   => "project_name"
    ),
'LIST ALL PROPERTIES FOR ATTRIBUTE "attribute_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "list_attribute_properties"
);

is(
    $foo->list_attributes(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
    'LIST ALL ATTRIBUTES IN FOLDER "location_path" FOR PROJECT "project_name";',
    "list_attributes"
);

is(
    $foo->list_caching_properties(
        CACHE_TYPE => "REPORT",
        PROJECT    => "project_name"
    ),
    'LIST ALL PROPERTIES FOR REPORT CACHING IN PROJECT "project_name";',
    "list_caching_properties"
);

is(
    $foo->list_custom_group_properties(
        CUSTOMGROUP => "customgroup_name",
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    ),
'LIST ALL PROPERTIES FOR CUSTOMGROUP "customgroup_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "list_custom_group_properties"
);

is(
    $foo->list_custom_groups(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'LIST ALL CUSTOMGROUPS IN FOLDER "location_path" FOR PROJECT "project_name";',
    "list_custom_groups"
);

is(
    $foo->list_dbconnection_properties( PROPERTIES => "ALL", DBCONNECTION => "dbConnection_name" ),
    'LIST ALL PROPERTIES FOR DBCONNECTION "dbConnection_name";',
    "list_dbconnection_properties1"
);

is(
    $foo->list_dbconnection_properties(
        PROPERTIES => [
            qw(ID NAME ODBCDSN DEFAULTLOGIN DRIVERMODE EXECMODE MAXCANCELATTEMPT MAXQUERYEXEC CHARSETENCODING TIMEOUT IDLETIMEOUT)
        ],
        DBCONNECTION => "dbConnection_name"
    ),
'LIST ID, NAME, ODBCDSN, DEFAULTLOGIN, DRIVERMODE, EXECMODE, MAXCANCELATTEMPT, MAXQUERYEXEC, CHARSETENCODING, TIMEOUT, IDLETIMEOUT FOR DBCONNECTION "dbConnection_name";',
    "list_dbconnection_properties2"
);

is(
    $foo->list_dbinstance_properties("dbinstance_name"),
    'LIST ALL PROPERTIES FOR DBINSTANCE "dbinstance_name";',
    "list_dbinstance_properties"
);

is(
    $foo->list_dblogin_properties( PROPERTIES => "ALL", DBLOGIN => "dblogin_name" ),
    'LIST ALL PROPERTIES FOR DBLOGIN "dblogin_name";',
    "list_dblogin_properties1"
);

is(
    $foo->list_dblogin_properties(
        PROPERTIES => [qw(ID NAME LOGIN)],
        DBLOGIN    => "dblogin_name"
    ),
    'LIST ID, NAME, LOGIN FOR DBLOGIN "dblogin_name";',
    "list_dblogin_properties2"
);

is(
    $foo->list_database_connection_properties("connection_id"),
    'LIST ALL PROPERTIES FOR DATABASE CONNECTION connection_id;',
    "list_database_connection_properties"
);

is(
    $foo->list_database_connections("ALL"),
    'LIST ALL DATABASE CONNECTIONS;',
    "list_database_connections"
);

is( $foo->list_events, 'LIST ALL EVENTS;', "list_events" );

is(
    $foo->list_fact_properties(
        FACT     => "fact_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'LIST ALL PROPERTIES FOR FACT "fact_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "list_fact_properties"
);

is(
    $foo->list_facts(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
    'LIST ALL FACTS IN FOLDER "location_path" FOR PROJECT "project_name";',
    "list_facts"
);

is(
    $foo->list_filter_properties(
        FILTER   => "filter_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'LIST ALL PROPERTIES FOR FILTER "filter_name" IN FOLDER "location_path" FROM PROJECT "project_name";',
    "list_filter_properties"
);

is(
    $foo->list_filters(
        LOCATION => "location_path",
        OWNER    => "login_name",
        PROJECT  => "project_name"
    ),
'LIST ALL FILTERS IN FOLDER "location_path" FOR OWNER "login_name" FOR PROJECT "project_name";',
    "list_filters"
);

is(
    $foo->list_folder_properties(
        FOLDER   => "folder_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'LIST ALL PROPERTIES FOR FOLDER "folder_name" IN "location_path" FOR PROJECT "project_name";',
    "list_folder_properties"
);

is(
    $foo->list_folders(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
    'LIST ALL FOLDERS IN "location_path" FOR PROJECT "project_name";',
    "list_folders"
);

is(
    $foo->list_job_properties("job_id"),
    'LIST ALL PROPERTIES FOR JOB job_id;',
    "list_job_properties"
);

is(
    $foo->list_jobs(
        TYPE => "ALL",
        USER => "login_name"
    ),
    'LIST ALL JOBS FOR USER "login_name";',
    "list_jobs"
);

is(
    $foo->list_lock_properties("project_name"),
    'LIST ALL PROPERTIES FOR LOCK IN PROJECT "project_name";',
    "list_lock_properties1"
);

is( $foo->list_lock_properties,
    'LIST ALL PROPERTIES FOR LOCK IN CONFIGURATION;',
    "list_lock_properties2" );

is(
    $foo->list_metric_properties(
        METRIC   => "metric_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'LIST ALL PROPERTIES FOR METRIC "metric_name" IN FOLDER "location_path" FROM PROJECT "project_name";',
    "list_metric_properties"
);

is(
    $foo->list_metrics(
        LOCATION => "location_path",
        OWNER    => "login_name",
        PROJECT  => "project_name"
    ),
'LIST ALL METRICS IN FOLDER "location_path" FOR OWNER "login_name" FOR PROJECT "project_name";',
    "list_metrics"
);

is(
    $foo->list_project_config_properties("project_name"),
'LIST ALL PROPERTIES FOR PROJECT CONFIGURATION FROM PROJECT "project_name";',
    "list_project_config_properties"
);

is(
    $foo->list_project_properties( PROPERTIES => "ALL", PROJECT => "project_name" ),
    'LIST ALL PROPERTIES FOR PROJECT "project_name";',
    "list_project_properties1"
);

is(
    $foo->list_project_properties(
        PROPERTIES => [qw(DESCRIPTION NAME ID CREATIONTIME MODIFICATIONTIME)],
        PROJECT    => "project_name"
    ),
'LIST DESCRIPTION, NAME, ID, CREATIONTIME, MODIFICATIONTIME FOR PROJECT "project_name";',
    "list_project_properties2"
);

is( $foo->list_projects_cluster, 'LIST ALL PROJECTS FOR CLUSTER;',
    "list_projects_cluster" );

is(
    $foo->list_projects("REGISTERED"),
    'LIST REGISTERED PROJECTS;',
    "list_projects"
);

is(
    $foo->list_report_cache_properties(
        REPORT_CACHE => "cache_name",
        PROJECT      => "project_name"
    ),
'LIST ALL PROPERTIES FOR REPORT CACHE "cache_name" IN PROJECT "project_name";',
    "list_report_cache_properties"
);

is(
    $foo->list_report_caches("project_name"),
    'LIST ALL REPORT CACHES FOR PROJECT "project_name";',
    "list_report_caches"
);

is(
    $foo->list_report_properties(
        REPORT   => "report_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
'LIST ALL PROPERTIES FOR REPORT "report_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "list_report_properties"
);

is(
    $foo->list_reports(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
    'LIST ALL REPORTS IN FOLDER "location_path" FOR PROJECT "project_name";',
    "list_reports"
);

is(
    $foo->list_schedule_properties("schedule_name"),
    'LIST ALL PROPERTIES FOR SCHEDULE "schedule_name";',
    "list_schedule_properties"
);

is(
    $foo->list_schedule_relations(
        SCHEDULE => "schedule_name",
        PROJECT  => "project_name"
    ),
'LIST ALL SCHEDULERELATIONS FOR SCHEDULE "schedule_name" IN PROJECT "project_name";',
    "list_schedule_relations"
);

is(
    $foo->list_security_filter_properties(
	PROPERTIES      => "ALL",
        SECURITY_FILTER => "sec_filter_name",
        LOCATION        => "location_path",
        PROJECT         => "project_name"
    ),
'LIST ALL PROPERTIES FOR SECURITY FILTER "sec_filter_name" FOLDER "location_path" OF PROJECT "project_name";',
    "list_security_filter_properties1"
);

is(
    $foo->list_security_filter_properties(
        PROPERTIES => [
            "NAME",               "ID",
            "TOP ATTRIBUTE LIST", "BOTTOM ATTRIBUTE LIST",
            "FILTER"
        ],
        SECURITY_FILTER => "sec_filter_name",
        LOCATION        => "location_path",
        PROJECT         => "project_name"
    ),
'LIST NAME, ID, TOP ATTRIBUTE LIST, BOTTOM ATTRIBUTE LIST, FILTER FOR SECURITY FILTER "sec_filter_name" FOLDER "location_path" OF PROJECT "project_name";',
    "list_security_filter_properties2"
);

is(
    $foo->list_security_filters(
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        LOCATION                 => "location_path",
        PROJECT                  => "project_name"
    ),
'LIST ALL SECURITY FILTERS USER "user_login_or_group_name" FOLDER "location_path" FOR PROJECT "project_name";',
    "list_security_filters"
);

is(
    $foo->list_security_role_properties(
        PROPERTIES    => [qw(NAME ID DESCRIPTION)],
        SECURITY_ROLE => "sec_role_name"
    ),
    'LIST NAME, ID, DESCRIPTION FOR SECURITY ROLE "sec_role_name";',
    "list_security_role_properties1"
);

is(
    $foo->list_security_role_properties( PROPERTIES => "ALL", SECURITY_ROLE => "sec_role_name" ),
    'LIST ALL PROPERTIES FOR SECURITY ROLE "sec_role_name";',
    "list_security_role_properties2"
);

is(
    $foo->list_security_role_privileges("sec_role_name"),
    'LIST ALL PRIVILEGES FOR SECURITY ROLE "sec_role_name";',
    "list_security_role_privileges"
);

is( $foo->list_security_roles, 'LIST ALL SECURITY ROLES;',
    "list_security_roles" );

is(
    $foo->list_server_config_properties("ALL"),
    'LIST ALL PROPERTIES FOR SERVER CONFIGURATION;',
    "list_server_config_properties1"
);

is(
    $foo->list_server_config_properties(
        [
            qw(MAXCONNECTIONTHREADS BACKUPFREQ USENTPERFORMANCEMON USEMSTRSCHEDULER BALSERVERTHREADS)
        ]
    ),
'LIST MAXCONNECTIONTHREADS, BACKUPFREQ, USENTPERFORMANCEMON, USEMSTRSCHEDULER, BALSERVERTHREADS FOR SERVER CONFIGURATION;',
    "list_server_config_properties2"
);

is(
    $foo->list_server_properties("machine_name"),
    'LIST ALL PROPERTIES FOR SERVER "machine_name";',
    "list_server_properties"
);

is( $foo->list_servers_cluster, 'LIST ALL SERVERS IN CLUSTER;',
    "list_servers_cluster" );

is(
    $foo->list_shortcut_properties(
        LOCATION            => "location_path",
        PROJECT_CONFIG_TYPE => "FOLDER",
        NAME                => "shortcut_name",
        PROJECT             => "project_name"
    ),
'LIST ALL PROPERTIES FOR SHORTCUT IN FOLDER "location_path" FOR FOLDER "shortcut_name" FOR PROJECT "project_name";',
    "list_shortcut_properties"
);

is(
    $foo->list_statistics_properties("project_name"),
    'LIST ALL PROPERTIES FOR STATISTICS FROM PROJECT "project_name";',
    "list_statistics_properties"
);

is(
    $foo->list_table_properties(
        TABLE   => "table_name",
        PROJECT => "project_name"
    ),
    'LIST ALL PROPERTIES FOR TABLE "table_name" FOR PROJECT "project_name";',
    "list_table_properties"
);

is(
    $foo->list_tables(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    ),
    'LIST ALL TABLES IN FOLDER "location_path" FOR PROJECT "project_name";',
    "list_tables"
);

is(
    $foo->list_user_conn_properties( USER => "login_name" ),
    'LIST ALL PROPERTIES FOR USER CONNECTION "login_name";',
    "list_user_conn_properties1"
);

is(
    $foo->list_user_conn_properties( SESSIONID => "sessionID" ),
    'LIST ALL PROPERTIES FOR USER CONNECTION SESSIONID sessionID;',
    "list_user_conn_properties1"
);

is(
    $foo->list_user_connections("ALL"),
    'LIST ALL USER CONNECTIONS;',
    "list_user_connections"
);

is(
    $foo->list_user_group_members("user_group_name"),
    'LIST MEMBERS FOR USER GROUP "user_group_name";',
    "list_user_group_members"
);

is(
    $foo->list_user_group_privileges("user_group_name"),
    'LIST ALL PRIVILEGES FOR USER GROUP "user_group_name";',
    "list_user_group_privileges"
);

is(
    $foo->list_user_group_properties( PROPERTIES => "ALL", USER_GROUP => "user_group_name" ),
    'LIST ALL PROPERTIES FOR USER GROUP "user_group_name";',
    "list_user_group_properties1"
);

is(
    $foo->list_user_group_properties(
        PROPERTIES => [qw(DESCRIPTION NAME ID LDAPLINK MEMBERS)],
        USER_GROUP => "user_group_name"
    ),
'LIST DESCRIPTION, NAME, ID, LDAPLINK, MEMBERS FOR USER GROUP "user_group_name";',
    "list_user_group_properties2"
);

is( $foo->list_user_groups, 'LIST ALL USER GROUPS;', "list_user_groups" );

is(
    $foo->list_user_privileges(
        TYPE => "ALL",
        USER => "login_name"
    ),
    'LIST ALL PRIVILEGES FOR USER "login_name";',
    "list_user_privileges"
);

is(
    $foo->list_user_profiles( USER => "ALL" ),
    'LIST ALL PROFILES FOR USERS;',
    "list_user_profiles1"
);

is(
    $foo->list_user_profiles(
        USER    => "Developer",
        PROJECT => "MicroStrategy tutorial"
    ),
'LIST ALL PROFILES FOR USER "Developer" FOR PROJECT "MicroStrategy tutorial";',
    "list_user_profiles2"
);

is(
    $foo->list_user_profiles(
        USER    => "Developer",
        PROJECT => [ "MicroStrategy Tutorial", "Customer Analysis Module" ]
    ),
'LIST ALL PROFILES FOR USER "Developer" FOR PROJECTS "MicroStrategy Tutorial", "Customer Analysis Module";',
    "list_user_profiles3"
);

is(
    $foo->list_user_profiles( USER => "Developer" ),
    'LIST ALL PROFILES FOR USER "Developer";',
    "list_user_profiles4"
);

is(
    $foo->list_user_profiles(
        USER    => "ALL",
        GROUP   => [ "group_name1", "group_nameN" ],
        PROJECT => [ "project_name1", "project_nameN" ]
    ),
'LIST ALL PROFILES FOR USERS IN GROUPS "group_name1", "group_nameN" FOR PROJECTS "project_name1", "project_nameN";',
    "list_user_profiles5"
);

is(
    $foo->list_user_profiles(
        USER    => "ALL",
        PROJECT => [ "MicroStrategy Tutorial", "Customer Analysis Module" ]
    ),
'LIST ALL PROFILES FOR USERS FOR PROJECTS "MicroStrategy Tutorial", "Customer Analysis Module";',
    "list_user_profiles6"
);

is(
    $foo->list_user_profiles(
        USER  => "ALL",
        GROUP => "Customers",
    ),
    'LIST ALL PROFILES FOR USERS IN GROUP "Customers";',
    "list_user_profiles7"
);

is(
    $foo->list_user_properties(
        PROPERTIES => [
            qw(FULLNAME ENABLED NTLINK LDAPLINK WHLINK DESCRIPTION ALLOWCHANGEPWD ALLOWSTDAUTH PASSWORDEXP PASSWORDEXPFREQ NAME ID GROUPS CHANGEPWD)
        ],
        USER => "login_name"
    ),
'LIST FULLNAME, ENABLED, NTLINK, LDAPLINK, WHLINK, DESCRIPTION, ALLOWCHANGEPWD, ALLOWSTDAUTH, PASSWORDEXP, PASSWORDEXPFREQ, NAME, ID, GROUPS, CHANGEPWD FOR USER "login_name";',
    "list_user_properties1"
);

is(
    $foo->list_user_properties( USER_GROUP => "user_group_name" ),
    'LIST ALL PROPERTIES FOR USERS IN GROUP "user_group_name";',
    "list_user_properties2"
);

is(
    $foo->list_whtables("project_name"),
    'LIST ALL AVAILABLE WHTABLES FOR PROJECT "project_name";',
    "list_whtables"
);

