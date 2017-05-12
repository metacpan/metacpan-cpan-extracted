#!perl -T

use Test::More;
use strict;
use warnings;

my $tests;

BEGIN {
    $tests = 36;
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib';
}

use Business::Intelligence::MicroStrategy::CommandManager;
my $foo = Business::Intelligence::MicroStrategy::CommandManager->new();

is(
    $foo->load_project("project_name"),
    'LOAD PROJECT "project_name";',
    "load_project"
);

is(
    $foo->load_projects_cluster(
        PROJECT => "project_name",
        SERVERS => "ALL"
    ),
    'LOAD PROJECT "project_name" TO CLUSTER ALL SERVERS;',
    "load_projects_cluster1"
);

is(
    $foo->load_projects_cluster(
        PROJECT => "project_name",
        SERVERS => [ "server_name1", "server_nameN" ]
    ),
'LOAD PROJECT "project_name" TO CLUSTER SERVERS "server_name1", "server_nameN";',
    "load_projects_cluster2"
);

my $k = $foo->privileges_list( [ "web_analyst", "desktop_designer" ] );
my $p = join( ", ", @$k );
is(
    $p,
'WEBMODIFYGRIDLEVELINDOC, WEBCREATEDERIVEDMETRICS, WEBNUMBERFORMATTING, WEBUSEREPORTOBJECTSWINDOW, WEBUSEVIEWFILTEREDITOR, WEBADDTOHISTORYLIST, WEBADVANCEDDRILLING, WEBALIASOBJECTS, WEBCHOOSEATTRFORMDISPLAY, WEBCONFIGURETOOLBARS, WEBCREATEFILELOCATION, WEBCREATENEWREPORT, WEBCREATEPRINTLOCATION, WEBDRILLONMETRICS, WEBEXECUTEBULKEXPORT, WEBEXECDATAMARTREPORTS, WEBFILTERSELECTIONS, WEBMANAGEOBJECTS, WEBMODIFYSUBTOTALS, WEBPIVOTREPORT, WEBREPORTDETAILS, WEBREPORTSQL, WEBSAVEREPORT, WEBSAVESHAREDREPORT, WEBSIMPLEGRAPHFORMATTING, WEBSIMULTANEOUSEXEC, WEBUSELOCKEDHEADERS, USEDOCUMENTEDITOR, DEFINEFREEFORMSQLREPORT, DEFINEOLAPCUBEREPORT, DEFINEQUERYBUILDERREP, FORMATGRAPH, MODIFYREPORTOBJECTLIST, USECONSOLIDATIONEDITOR, USECUSTOMGROUPEDITOR, USEDATAMARTEDITOR, USEDESIGNMODE, USEDRILLMAPEDITOR, USEFINDANDREPLACEDIALOG, USEFORMATTINGEDITOR, USEHTMLDOCUMENTEDITOR, USEMETRICEDITOR, USEPROJECTDOCUMENTATION, USEPROMPTEDITOR, USEREPORTFILTEREDITOR, USESUBTOTALSEDITOR, USETEMPLATEEDITOR, USEVLDBEDITOR, VIEWETLINFO',
    "privileges_list"
);

is(
    $foo->lock_configuration("FORCE"),
    'LOCK CONFIGURATION FORCE;',
    "lock_configuration"
);

is(
    $foo->lock_project(
        PROJECT => "project_name",
        FORCE   => "TRUE"
    ),
    'LOCK PROJECT "project_name" FORCE;',
    "lock_project"
);

is(
    $foo->log_event(
        MESSAGE => "event_message",
        TYPE    => "ERROR"
    ),
    'LOG EVENT "event_message" TYPE ERROR;',
    "log_event"
);

is(
    $foo->purge_caching(
        TYPE    => "REPORT",
        PROJECT => "project_name"
    ),
    'PURGE REPORT CACHING IN PROJECT "project_name";',
    "purge_caching"
);

is(
    $foo->purge_statistics(
        START_DATE => "start_date",
        END_DATE   => "end_date",
        TIMEOUT    => "seconds"
    ),
    'PURGE STATISTICS FROM start_date TO end_date TIMEOUT seconds;',
    "purge_statistics"
);

is(
    $foo->register_project(
        PROJECT  => "project_name",
        AUTOLOAD => "FALSE"
    ),
    'REGISTER PROJECT "project_name" NOAUTOLOAD;',
    "register_project"
);

is(
    $foo->restart_server("machine_name"),
    'RESTART SERVER IN "machine_name";',
    "restart_server"
);

is(
    $foo->resume_project("project_name"),
    'RESUME PROJECT "project_name";',
    "resume_project"
);

is(
    $foo->revoke_privileges(
        PRIVILEGE => "ALL",
        USER      => "login_name"
    ),
    'REVOKE ALL PRIVILEGES FROM USER "login_name";',
    "revoke_privileges1"
);

is(
    $foo->revoke_privileges(
        PRIVILEGE => [ "privilege1", "privilegeN" ],
        GROUP     => "user_group_name",
    ),
    'REVOKE privilege1, privilegeN FROM GROUP "user_group_name";',
    "revoke_privileges2"
);

is(
    $foo->revoke_security_filter(
        SECURITY_FILTER          => "sec_filter_name",
        LOCATION                 => "location_path",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "login_or_group_name",
        PROJECT                  => "project_name"
    ),
'REVOKE SECURITY FILTER "sec_filter_name" FOLDER "location_path" FROM USER "login_or_group_name" ON PROJECT "project_name";',
    "revoke_security_filter"
);

is(
    $foo->revoke_security_roles(
        SECURITY_ROLE            => "sec_role_name",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "login_name",
        PROJECT                  => "project_name"
    ),
'REVOKE SECURITY ROLE "sec_role_name" FROM USER "login_name" ON PROJECT "project_name";',
    "revoke_security_roles"
);

is(
    $foo->run_command("executable_program"),
    'RUN COMMAND "executable_program";',
    "run_command"
);

is(
    $foo->send_message(
        MESSAGE => "message",
        USER    => "ALL"
    ),
    'SEND MESSAGE "message" TO ALL USERS;',
    "send_message"
);

is(
    $foo->set_property_hidden(
        HIDDEN              => "TRUE",
        PROJECT_CONFIG_TYPE => "FOLDER",
        OBJECT_NAME         => "object_name",
        LOCATION            => "location_path",
        PROJECT             => "project_name"
    ),
'SET PROPERTY HIDDEN TRUE FOR FOLDER "object_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "set_property_hidden"
);

is(
    $foo->start_server("machine_name"),
    'START SERVER IN "machine_name";',
    "start_server"
);

is(
    $foo->start_service(
        SERVICE => "service_name",
        SERVER  => "machine_name"
    ),
    'START SERVICE "service_name" IN "machine_name";',
    "start_service"
);

is(
    $foo->stop_server("machine_name"),
    'STOP SERVER IN "machine_name";',
    "stop_server"
);

is(
    $foo->stop_service(
        SERVICE => "service_name",
        SERVER  => "machine_name"
    ),
    'STOP SERVICE "service_name" IN "machine_name";',
    "stop_service"
);

is(
    $foo->take_ownership(
        OBJECT_TYPE => "conf_object_type",
        OBJECT_NAME => "object_name",
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    ),
'TAKE OWNERSHIP FOR conf_object_type "object_name" IN FOLDER "location_path" FOR PROJECT "project_name";',
    "take_ownership1"
);

is(
    $foo->take_ownership(
        OBJECT_TYPE => "FOLDER",
        OBJECT_NAME => "folder_name",
        RECURSIVELY => "TRUE",
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    ),
'TAKE OWNERSHIP FOR FOLDER "folder_name" RECURSIVELY IN FOLDER "location_path" FOR PROJECT "project_name";',
    "take_ownership2"
);

is(
    $foo->trigger_event("event_name"),
    'TRIGGER EVENT "event_name";',
    "trigger_event"
);

is(
    $foo->unload_project("project_name"),
    'UNLOAD PROJECT "project_name";',
    "unload_project"
);

is(
    $foo->unload_projects_cluster(
        PROJECT => "project_name",
        SERVERS => "ALL"
    ),
    'UNLOAD PROJECT "project_name" FROM CLUSTER ALL SERVERS;',
    "unload_project_cluster"
);

is( $foo->unlock_configuration, 'UNLOCK CONFIGURATION FORCE;',
    "unlock_configuration" );

is(
    $foo->unlock_project("project_name"),
    'UNLOCK PROJECT "project_name" FORCE;',
    "unlock_project"
);

is(
    $foo->unregister_project("project_name"),
    'UNREGISTER PROJECT "project_name";',
    "unregister_project"
);

is(
    $foo->update_project("project_name"),
    'UPDATE PROJECT "project_name";',
    "update_project"
);

is(
    $foo->update_schema(
        REFRESHSCHEMA     => "TRUE",
        RECALTABLEKEYS    => "TRUE",
        RECALTABLELOGICAL => "TRUE",
        RECALOBJECTCACHE  => "TRUE",
        PROJECT           => "project_name"
    ),
'UPDATE SCHEMA REFRESHSCHEMA RECALTABLEKEYS RECALTABLELOGICAL RECALOBJECTCACHE FOR PROJECT "project_name";',
    "update_schema1"
);

is(
    $foo->update_schema(
        REFRESHSCHEMA     => "FALSE",
        RECALTABLEKEYS    => "FALSE",
        RECALTABLELOGICAL => "FALSE",
        RECALOBJECTCACHE  => "FALSE",
        PROJECT           => "project_name"
    ),
    'UPDATE SCHEMA FOR PROJECT "project_name";',
    "update_schema2"
);

is(
    $foo->update_structure(
        COLMERGEOPTION => "RECENT",
        WHTABLE        => "warehouse_table_name",
        PROJECT        => "project_name"
    ),
'UPDATE STRUCTURE COLMERGEOPTION RECENT FOR WHTABLE "warehouse_table_name" FOR PROJECT "project_name";',
    "update_structure1"
);

is(
    $foo->update_structure(
        COLMERGEOPTION => "MAXDENOMINATOR",
        PROJECT        => "project_name"
    ),
'UPDATE STRUCTURE COLMERGEOPTION MAXDENOMINATOR FOR PROJECT "project_name";',
    "update_structure2"
);

