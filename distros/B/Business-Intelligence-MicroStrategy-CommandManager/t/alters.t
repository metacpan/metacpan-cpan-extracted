#!perl -T

use Test::More;
use strict;
use warnings;

my $tests;

BEGIN {
    $tests = 65;
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib';
}

use Business::Intelligence::MicroStrategy::CommandManager;
my $foo = Business::Intelligence::MicroStrategy::CommandManager->new();

is(
    $foo->alter_attribute(
        ATTRIBUTE                => "Day",
        LOCATION                 => '\Schema Objects\Attributes',
        NEW_NAME                 => "Duplicate_Day",
        NEW_LOCATION             => '\Schema Objects\Attributes\Time',
        REPORTDISPLAYFORMS       => ["ID"],
        BROWSEDISPLAYFORMS       => ["ID"],
        ELEMDISPLAY              => "UNLOCKED",
        SECFILTERSTOELEMBROWSING => "TRUE",
        ENABLEELEMCACHING        => "TRUE",
        PROJECT                  => "MicroStrategy Tutorial"
    ),
'ALTER ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" NAME "Duplicate_Day" FOLDER "\Schema Objects\Attributes\Time" REPORTDISPLAYFORMS "ID" BROWSEDISPLAYFORMS "ID" ELEMDISPLAY UNLOCKED SECFILTERSTOELEMBROWSING TRUE ENABLEELEMCACHING TRUE FOR PROJECT "MicroStrategy Tutorial";',
    "alter_attribute1"
);

is(
    $foo->alter_attribute(
        ATTRIBUTE          => "Customer",
        LOCATION           => '\Schema Objects\Attributes\Customer',
        HIDDEN             => "TRUE",
        NEW_NAME           => "Customer Copy",
        DESCRIPTION        => "Customer Copy Description",
        NEW_LOCATION       => '\Schema Objects\Attributes\Customer\Copies',
        REPORTDISPLAYFORMS => [ "ID", "DESC" ],
        BROWSEDISPLAYFORMS => [ "ID", "DESC" ],
        ELEMDISPLAY        => "LIMIT 100",
        SECFILTERSTOELEMBROWSING => "TRUE",
        ENABLEELEMCACHING        => "TRUE",
        PROJECT                  => "MicroStrategy Tutorial"
    ),
'ALTER ATTRIBUTE "Customer" IN FOLDER "\Schema Objects\Attributes\Customer" HIDDEN TRUE NAME "Customer Copy" DESCRIPTION "Customer Copy Description" FOLDER "\Schema Objects\Attributes\Customer\Copies" REPORTDISPLAYFORMS "ID", "DESC" BROWSEDISPLAYFORMS "ID", "DESC" ELEMDISPLAY LIMIT 100 SECFILTERSTOELEMBROWSING TRUE ENABLEELEMCACHING TRUE FOR PROJECT "MicroStrategy Tutorial";',
    "alter_attribute2"
);

is(
    $foo->alter_attribute(
        ATTRIBUTE                => "Day",
        LOCATION                 => '\Schema Objects\Attributes',
        NEW_NAME                 => "Duplicate_Day",
        NEW_LOCATION             => '\Schema Objects\Attributes\Time',
        REPORTDISPLAYFORMS       => "NONE",
        BROWSEDISPLAYFORMS       => ["ID"],
        ELEMDISPLAY              => "UNLOCKED",
        SECFILTERSTOELEMBROWSING => "TRUE",
        ENABLEELEMCACHING        => "TRUE",
        PROJECT                  => "MicroStrategy Tutorial"
    ),
'ALTER ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" NAME "Duplicate_Day" FOLDER "\Schema Objects\Attributes\Time" REPORTDISPLAYFORMS NONE BROWSEDISPLAYFORMS "ID" ELEMDISPLAY UNLOCKED SECFILTERSTOELEMBROWSING TRUE ENABLEELEMCACHING TRUE FOR PROJECT "MicroStrategy Tutorial";',
    "alter_attribute3"
);

is(
    $foo->alter_attribute_form_expression(
        ATTRIBUTEFORMEXP => "ORDER_DATE",
        MAPPINGMODE      => "AUTOMATIC",
        ATTRIBUTEFORM    => "ID",
        ATTRIBUTE        => "Day",
        LOCATION         => "\\Schema Objects\\Attributes",
        PROJECT          => "MicroStrategy Tutorial"
    ),
'ALTER ATTRIBUTEFORMEXP "ORDER_DATE" MAPPINGMODE AUTOMATIC FOR ATTRIBUTEFORM "ID" FOR ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";',
    "alter_attribute_form_expression1"
);

is(
    $foo->alter_attribute_form_expression(
        ATTRIBUTEFORMEXP => "ORDER_DATE",
        MAPPINGMODE      => [ "ORDER_DETAIL", "ORDER_FACT" ],
        ATTRIBUTEFORM    => "ID",
        ATTRIBUTE        => "Day",
        LOCATION         => "\\Schema Objects\\Attributes",
        PROJECT          => "MicroStrategy Tutorial"
    ),
'ALTER ATTRIBUTEFORMEXP "ORDER_DATE" MAPPINGMODE EXPSOURCETABLES "ORDER_DETAIL", "ORDER_FACT" FOR ATTRIBUTEFORM "ID" FOR ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";',
    "alter_attribute_form_expression2"
);

is(
    $foo->alter_attribute_form_expression(
        ATTRIBUTEFORMEXP => "ORDER_ID",
        OVERWRITE        => "TRUE",
        LOOKUPTABLE      => "CUSTOMERS",
        MAPPINGMODE      => "AUTOMATIC",
        ATTRIBUTEFORM    => "ID",
        ATTRIBUTE        => "CUSTOMER",
        LOCATION         => '\Schema Objects\Attributes',
        PROJECT          => "MicroStrategy Tutorial"
    ),
'ALTER ATTRIBUTEFORMEXP "ORDER_ID" OVERWRITE LOOKUPTABLE "CUSTOMERS" MAPPINGMODE AUTOMATIC FOR ATTRIBUTEFORM "ID" FOR ATTRIBUTE "CUSTOMER" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";',
    "alter_attribute_form_expression3"
);

is(
    $foo->alter_configuration_ace(
        CONF_OBJECT_TYPE         => "SCHEDULE",
        OBJECT_NAME              => "All the time",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "DENIEDALL"
    ),
'ALTER ACE FOR SCHEDULE "All the time" USER "Developer" ACCESSRIGHTS DENIEDALL;',
    "alter_configuration_ace1"
);

is(
    $foo->alter_configuration_ace(
        CONF_OBJECT_TYPE         => "SCHEDULE",
        OBJECT_NAME              => "All the time",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "MODIFY"
    ),
'ALTER ACE FOR SCHEDULE "All the time" USER "Developer" ACCESSRIGHTS MODIFY;',
    "alter_configuration_ace2"
);

is(
    $foo->alter_configuration_ace(
        CONF_OBJECT_TYPE         => "SCHEDULE",
        OBJECT_NAME              => "All the time",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "CUSTOM",
        ACCESSRIGHTS_CUSTOM      => { BROWSE => "DENY", READ => "DENY" }
    ),
'ALTER ACE FOR SCHEDULE "All the time" USER "Developer" ACCESSRIGHTS CUSTOM DENY BROWSE, READ;',
    "alter_configuration_ace3"
);

is(
    $foo->alter_configuration_ace(
        CONF_OBJECT_TYPE         => "SCHEDULE",
        OBJECT_NAME              => "All the time",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "CUSTOM",
        ACCESSRIGHTS_CUSTOM      => { CONTROL => "GRANT" }
    ),
'ALTER ACE FOR SCHEDULE "All the time" USER "Developer" ACCESSRIGHTS CUSTOM GRANT CONTROL;',
    "alter_configuration_ace4"
);

is(
    $foo->alter_configuration_ace(
        CONF_OBJECT_TYPE         => "SCHEDULE",
        OBJECT_NAME              => "All the time",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "Developer",
        ACCESSRIGHTS             => "CUSTOM",
        ACCESSRIGHTS_CUSTOM      => "CUSTOM",
        ACCESSRIGHTS_CUSTOM      => {
            BROWSE  => "GRANT",
            READ    => "GRANT",
            WRITE   => "DENY",
            DELETE  => "DENY",
            CONTROL => "DENY",
            USE     => "GRANT",
            EXECUTE => "GRANT"
        }
    ),
'ALTER ACE FOR SCHEDULE "All the time" USER "Developer" ACCESSRIGHTS CUSTOM GRANT BROWSE, EXECUTE, READ, USE DENY CONTROL, DELETE, WRITE;',
    "alter_configuration_ace5"
);

is(
    $foo->alter_configuration_ace(
        CONF_OBJECT_TYPE         => "SCHEDULE",
        OBJECT_NAME              => "All the Time",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "joe",
        ACCESSRIGHTS             => "CUSTOM",
        ACCESSRIGHTS_CUSTOM      => { BROWSE => 'DENY', READ => 'DENY' }
    ),
'ALTER ACE FOR SCHEDULE "All the Time" USER "joe" ACCESSRIGHTS CUSTOM DENY BROWSE, READ;',
    "alter_configuration_ace6"
);

is(
    $foo->alter_connection_map(
        USER       => "Developer",
        DBINSTANCE => "Tutorial Data",
        DBLOGIN    => "Data",
        PROJECT    => "MicroStrategy Tutorial"
    ),
'ALTER CONNECTION MAP FOR USER "Developer" DBINSTANCE "Tutorial Data" DBLOGIN "Data" ON PROJECT "MicroStrategy Tutorial";',
    "alter_connection_map1"
);

is(
    $foo->alter_connection_map(
        USER         => "jsmith",
        DBINSTANCE   => "MSI_DB",
        DBCONNECTION => "MSI_DB_Conn",
        DBLOGIN      => "MSI_USER",
        PROJECT      => "MicroStrategy Tutorial"
    ),
'ALTER CONNECTION MAP FOR USER "jsmith" DBINSTANCE "MSI_DB" DBCONNECTION "MSI_DB_Conn" DBLOGIN "MSI_USER" ON PROJECT "MicroStrategy Tutorial";',
    "alter_connection_map2"
);

is(
    $foo->alter_connection_map(
        USER         => "jpmorgan",
        DBINSTANCE   => "CHASE",
        DBCONNECTION => "PROD",
        DBLOGIN      => "prod",
        PROJECT      => "MicroStrategy Tutorial"
    ),
'ALTER CONNECTION MAP FOR USER "jpmorgan" DBINSTANCE "CHASE" DBCONNECTION "PROD" DBLOGIN "prod" ON PROJECT "MicroStrategy Tutorial";',
    "alter_connection_map3"
);

is(
    $foo->alter_custom_group(
        CUSTOMGROUP     => "My Custom Groups",
        LOCATION        => '\Public Objects\Custom Groups',
        NEW_NAME        => "Modified My Custom Groups",
        NEW_DESCRIPTION => "Modified Copy of My Custom Groups",
        NEW_LOCATION => '\Public Objects\Custom Groups\Modified Custom Groups',
        ENABLEHIERARCHICALDISPLAY => "FALSE",
        ENABLESUBTOTALDISPLAY     => "TRUE",
        ELEMENTHEADERPOSITION     => "ABOVE",
        HIDDEN                    => "FALSE",
        PROJECT                   => "MicroStrategy Tutorial"
    ),
'ALTER CUSTOMGROUP "My Custom Groups" IN FOLDER "\Public Objects\Custom Groups" NAME "Modified My Custom Groups" DESCRIPTION "Modified Copy of My Custom Groups" FOLDER "\Public Objects\Custom Groups\Modified Custom Groups" ENABLEHIERARCHICALDISPLAY FALSE ENABLESUBTOTALDISPLAY TRUE ELEMENTHEADERPOSITION ABOVE HIDDEN FALSE FOR PROJECT "MicroStrategy Tutorial";',
    "alter_custom_group1"
);

is(
    $foo->alter_custom_group(
        CUSTOMGROUP               => "Copy of Age Groups",
        LOCATION                  => '\Public Objects\Custom Groups',
        NEW_NAME                  => "Modified Age Groups",
        NEW_DESCRIPTION           => "Modified copy of Age Groups",
        ENABLEHIERARCHICALDISPLAY => "TRUE",
        ENABLESUBTOTALDISPLAY     => "TRUE",
        ELEMENTHEADERPOSITION     => "BELOW",
        HIDDEN                    => "TRUE",
        PROJECT                   => "MicroStrategy Tutorial"
    ),
'ALTER CUSTOMGROUP "Copy of Age Groups" IN FOLDER "\Public Objects\Custom Groups" NAME "Modified Age Groups" DESCRIPTION "Modified copy of Age Groups" ENABLEHIERARCHICALDISPLAY TRUE ENABLESUBTOTALDISPLAY TRUE ELEMENTHEADERPOSITION BELOW HIDDEN TRUE FOR PROJECT "MicroStrategy Tutorial";',
    "alter_custom_group2"
);

is(
    $foo->alter_dbconnection(
        DBCONNECTION     => "DBConn1",
        NEW_NAME         => "DBConnection2",
        ODBCDSN          => "MSI_ODBC",
        DEFAULTLOGIN     => "MSI_USER",
        DRIVERMODE       => "MULTIPROCESS",
        EXECMODE         => "SYNCHRONOUS",
        USEEXTENDEDFETCH => "TRUE",
        USEPARAMQUERIES  => "TRUE",
        MAXCANCELATTEMPT => "100",
        MAXQUERYEXEC     => "100",
        MAXCONNATTEMPT   => "100",
        CHARSETENCODING  => "MULTIBYTE",
        TIMEOUT          => "100",
        IDLETIMEOUT      => "100"
    ),
'ALTER DBCONNECTION "DBConn1" NAME "DBConnection2" ODBCDSN "MSI_ODBC" DEFAULTLOGIN "MSI_USER" DRIVERMODE MULTIPROCESS EXECMODE SYNCHRONOUS USEEXTENDEDFETCH TRUE USEPARAMQUERIES TRUE MAXCANCELATTEMPT 100 MAXQUERYEXEC 100 MAXCONNATTEMPT 100 CHARSETENCODING MULTIBYTE TIMEOUT 100 IDLETIMEOUT 100;',
    "alter_dbconnection1"
);

is(
    $foo->alter_dbconnection( DBCONNECTION => "DBConn1", TIMEOUT => "100" ),
    'ALTER DBCONNECTION "DBConn1" TIMEOUT 100;',
    "alter_dbconnection2"
);

is(
    $foo->alter_dbconnection(
        DBCONNECTION     => "PROD",
        NEW_NAME         => "TEST",
        ODBCDSN          => "PRODODBC",
        DEFAULTLOGIN     => "ANON",
        DRIVERMODE       => "MULTIPROCESS",
        EXECMODE         => "SYNCHRONOUS",
        USEEXTENDEDFETCH => "TRUE",
        USEPARAMQUERIES  => "TRUE",
        MAXCANCELATTEMPT => 60,
        MAXQUERYEXEC     => 60,
        MAXCONNATTEMPT   => 60,
        CHARSETENCODING  => "MULTIBYTE",
        TIMEOUT          => 60,
        IDLETIMEOUT      => 60,
    ),
'ALTER DBCONNECTION "PROD" NAME "TEST" ODBCDSN "PRODODBC" DEFAULTLOGIN "ANON" DRIVERMODE MULTIPROCESS EXECMODE SYNCHRONOUS USEEXTENDEDFETCH TRUE USEPARAMQUERIES TRUE MAXCANCELATTEMPT 60 MAXQUERYEXEC 60 MAXCONNATTEMPT 60 CHARSETENCODING MULTIBYTE TIMEOUT 60 IDLETIMEOUT 60;',
    "alter_dbconnection3"
);

is(
    $foo->alter_dbconnection(
        DBCONNECTION     => "DBConn1",
        NEW_NAME         => "DBConnection2",
        ODBCDSN          => "MSI_ODBC",
        DEFAULTLOGIN     => "MSI_USER",
        DRIVERMODE       => "MULTIPROCESS",
        EXECMODE         => "SYNCHRONOUS",
        USEEXTENDEDFETCH => "TRUE",
        USEPARAMQUERIES  => "TRUE",
        MAXCANCELATTEMPT => "100",
        MAXQUERYEXEC     => "100",
        MAXCONNATTEMPT   => "100",
        CHARSETENCODING  => "MULTIBYTE",
        TIMEOUT          => "100",
        IDLETIMEOUT      => "100"
    ),
'ALTER DBCONNECTION "DBConn1" NAME "DBConnection2" ODBCDSN "MSI_ODBC" DEFAULTLOGIN "MSI_USER" DRIVERMODE MULTIPROCESS EXECMODE SYNCHRONOUS USEEXTENDEDFETCH TRUE USEPARAMQUERIES TRUE MAXCANCELATTEMPT 100 MAXQUERYEXEC 100 MAXCONNATTEMPT 100 CHARSETENCODING MULTIBYTE TIMEOUT 100 IDLETIMEOUT 100;',
    "alter_dbconnection1"
);

is(
    $foo->alter_dbconnection( DBCONNECTION => "DBConn1", TIMEOUT => "100" ),
    'ALTER DBCONNECTION "DBConn1" TIMEOUT 100;',
    "alter_dbconnection2"
);

is(
    $foo->alter_dblogin(
        DBLOGIN      => "MSI_USER",
        NEW_NAME     => "MSI_USER2",
        NEW_LOGIN    => "MSI_USER_login",
        NEW_PASSWORD => "resu_ism"
    ),
'ALTER DBLOGIN "MSI_USER" NAME "MSI_USER2" LOGIN "MSI_USER_login" PASSWORD "resu_ism";',
    "alter_dblogin1"
);

is(
    $foo->alter_dblogin(
        DBLOGIN      => "Data",
        NEW_LOGIN    => "dbadmin",
        NEW_PASSWORD => "dbadmin"
    ),
    'ALTER DBLOGIN "Data" LOGIN "dbadmin" PASSWORD "dbadmin";',
    "alter_dblogin2"
);

is(
    $foo->alter_dblogin(
        DBLOGIN      => "jen",
        NEW_NAME     => "jenny",
        NEW_LOGIN    => "abc123",
        NEW_PASSWORD => "sprint"
    ),
    'ALTER DBLOGIN "jen" NAME "jenny" LOGIN "abc123" PASSWORD "sprint";',
    "alter_dblogin"
);

is(
    $foo->alter_dbinstance(
        DBINSTANCE        => "PROD",
        NEW_NAME          => "PROD1",
        DBCONNTYPE        => "ORACLE 9i",
        DBCONNECTION      => "ORACL",
        DESCRIPTION       => "PROD DB",
        DATABASE          => "DASHP101",
        TABLESPACE        => "MSI_TABLESPACE",
        PRIMARYDBINSTANCE => "PROD2",
        DATAMART          => "DM",
        TABLEPREFIX       => "MSI",
        HIGHTHREADS       => 5,
        MEDIUMTHREADS     => 5,
        LOWTHREADS        => 10
    ),
'ALTER DBINSTANCE "PROD" NAME "PROD1" DBCONNTYPE "ORACLE 9i" DBCONNECTION "ORACL" DESCRIPTION "PROD DB" DATABASE "DASHP101" TABLESPACE "MSI_TABLESPACE" PRIMARYDBINSTANCE "PROD2" DATAMART "DM" TABLEPREFIX "MSI" HIGHTHREADS 5 MEDIUMTHREADS 5 LOWTHREADS 10;',
    "alter_dbinstance"
);

is(
    $foo->alter_element_caching(
        PROJECT                => "MicroStrategy Tutorial",
        MAXRAMUSAGE            => "10240",
        MAXRAMUSAGECLIENT      => "512",
        CREATECACHESPERDBLOGIN => "TRUE",
        CREATECACHESPERDBCONN  => "TRUE"
    ),
'ALTER ELEMENT CACHING IN PROJECT "MicroStrategy Tutorial" MAXRAMUSAGE 10240 MAXRAMUSAGECLIENT 512 CREATECACHESPERDBLOGIN TRUE CREATECACHESPERDBCONN TRUE;',
    "alter_element_caching1"
);

is(
    $foo->alter_element_caching(
        PROJECT           => "MicroStrategy Tutorial",
        MAXRAMUSAGE       => "10240",
        MAXRAMUSAGECLIENT => "512"
    ),
'ALTER ELEMENT CACHING IN PROJECT "MicroStrategy Tutorial" MAXRAMUSAGE 10240 MAXRAMUSAGECLIENT 512;',
    "alter_element_caching2"
);

is(
    $foo->alter_event( EVENT => "Database Load", NEW_NAME => "DBMS Load" ),
    'ALTER EVENT "Database Load" NAME "DBMS Load";',
    "alter_event1"
);

is(
    $foo->alter_event(
        EVENT           => "Database Load",
        NEW_NAME        => "DBMS Load",
        NEW_DESCRIPTION => "Modified Database Load"
    ),
'ALTER EVENT "Database Load" NAME "DBMS Load" DESCRIPTION "Modified Database Load";',
    "alter_event2"
);

is(
    $foo->alter_fact(
        FACT            => "Revenue",
        LOCATION        => '\Public Objects',
        NEW_NAME        => "Copy Revenue",
        NEW_DESCRIPTION => "Altered Revenue",
        NEW_LOCATION    => '\Project Objects',
        HIDDEN          => "TRUE",
        PROJECT         => "MicroStrategy Tutorial"
    ),
'ALTER FACT "Revenue" IN FOLDER "\Public Objects" NAME "Copy Revenue" DESCRIPTION "Altered Revenue" FOLDER "\Project Objects" HIDDEN TRUE FOR PROJECT "MicroStrategy Tutorial";',
    "alter_fact1"
);

is(
    $foo->alter_filter(
        FILTER          => "South Region",
        LOCATION        => '\Public Objects\Filters',
        NEW_NAME        => "Southeast Region",
        NEW_EXPRESSION  => 'Region@ID=3',
        NEW_DESCRIPTION => "Modified South Region filter",
        NEW_LOCATION    => '\Public Objects\Filters\South Region',
        HIDDEN          => "FALSE",
        PROJECT         => "MicroStrategy Tutorial"
    ),
'ALTER FILTER "South Region" IN FOLDER "\Public Objects\Filters" NAME "Southeast Region" EXPRESSION "Region@ID=3" DESCRIPTION "Modified South Region filter" LOCATION "\Public Objects\Filters\South Region" HIDDEN FALSE ON PROJECT "MicroStrategy Tutorial";',
    "alter_filter1"
);

is(
    $foo->alter_filter(
        FILTER   => 'On Promotion(CM)',
        LOCATION => '\Public Objects\Filters',
        HIDDEN   => "FALSE",
        PROJECT  => "MicroStrategy Tutorial"
    ),
'ALTER FILTER "On Promotion(CM)" IN FOLDER "\Public Objects\Filters" HIDDEN FALSE ON PROJECT "MicroStrategy Tutorial";',
    "alter_filter2"
);

is(
    $foo->alter_filter(
        FILTER         => "West Region",
        LOCATION       => '\Public Objects\Filters',
        NEW_NAME       => "East Region",
        NEW_EXPRESSION => 'Region@ID=2',
        PROJECT        => "MicroStrategy Tutorial"
    ),
'ALTER FILTER "West Region" IN FOLDER "\Public Objects\Filters" NAME "East Region" EXPRESSION "Region@ID=2" ON PROJECT "MicroStrategy Tutorial";',
    "alter_filter3"
);

is(
    $foo->alter_filter(
        FILTER          => "West Region",
        LOCATION        => '\Public Objects\Filters',
        NEW_NAME        => "East Region",
        NEW_EXPRESSION  => 'Region@ID=2',
        PROJECT         => "MicroStrategy Tutorial",
        NEW_DESCRIPTION => "Copy of West Region",
        NEW_LOCATION    => '\Public Objects\Filters\West Region',
        HIDDEN          => "TRUE",
        PROJECT         => "MT"
    ),
'ALTER FILTER "West Region" IN FOLDER "\Public Objects\Filters" NAME "East Region" EXPRESSION "Region@ID=2" DESCRIPTION "Copy of West Region" LOCATION "\Public Objects\Filters\West Region" HIDDEN TRUE ON PROJECT "MT";',
    "alter_filter"
);

is(
    $foo->alter_folder(
        FOLDER          => "Regions",
        LOCATION        => '\Public Objects',
        NEW_NAME        => "Super Regions",
        NEW_DESCRIPTION => "New Super Regions",
        HIDDEN          => "TRUE",
        NEW_LOCATION    => '\Public Objects\Regions',
        PROJECT         => "MT"
    ),
'ALTER FOLDER "Regions" IN "\Public Objects" NAME "Super Regions" DESCRIPTION "New Super Regions" HIDDEN TRUE LOCATION "\Public Objects\Regions" FOR PROJECT "MT";',
    "alter_folder"
);

is(
    $foo->alter_folder_ace(
        FOLDER                   => "Regions",
        LOCATION                 => '\Public Objects',
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "jen",
        ACCESSRIGHTS             => "FULLCONTROL",
        CHILDRENACCESSRIGHTS     => "FULLCONTROL",
        PROJECT                  => "MicroStrategy Tutorial"
    ),
'ALTER ACE FOR FOLDER "Regions" IN FOLDER "\Public Objects" USER "jen" ACCESSRIGHTS FULLCONTROL CHILDRENACCESSRIGHTS FULLCONTROL FOR PROJECT "MicroStrategy Tutorial";',
    "alter_folder_ace1"
);

is(
    $foo->alter_folder_ace(
        FOLDER                      => "Subtotals",
        LOCATION                    => '\Project Objects',
        USER_OR_GROUP               => "USER",
        USER_LOGIN_OR_GROUP_NAME    => "jen",
        ACCESSRIGHTS                => "CUSTOM",
        ACCESSRIGHTS_CUSTOM         => { BROWSE => 'DENY', READ => 'DENY' },
        CHILDRENACCESSRIGHTS        => "CUSTOM",
        CHILDRENACCESSRIGHTS_CUSTOM => { BROWSE => "GRANT", READ => "GRANT" },
        PROJECT                     => "MicroStrategy Tutorial"
    ),
'ALTER ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "jen" ACCESSRIGHTS CUSTOM DENY BROWSE, READ CHILDRENACCESSRIGHTS CUSTOM GRANT BROWSE, READ FOR PROJECT "MicroStrategy Tutorial";',
    "alter_folder_ace2"
);

is(
    $foo->alter_folder_acl(
        FOLDER              => "Subtotals",
        LOCATION            => '\Project Objects',
        PROPAGATE_OVERWRITE => "TRUE",
        RECURSIVELY         => "TRUE",
        PROJECT             => "MicroStrategy Tutorial"

    ),
'ALTER ACL FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" PROPAGATE OVERWRITE RECURSIVELY FOR PROJECT "MicroStrategy Tutorial";',
    "alter_folder_acl"
);

is(
    $foo->alter_metric(
        METRIC          => "New Metric",
        LOCATION        => '\Public Objects\Metrics\Count Metrics',
        NEW_NAME        => "Metric Count",
        NEW_EXPRESSION  => "count",
        NEW_DESCRIPTION => "New Metric Desc",
        NEW_LOCATION    => '\Public Objects\Metrics\Count Metrics',
        HIDDEN          => "FALSE",
        PROJECT         => "MT"
    ),
'ALTER METRIC "New Metric" IN FOLDER "\Public Objects\Metrics\Count Metrics" NAME "Metric Count" EXPRESSION "count" DESCRIPTION "New Metric Desc" LOCATION "\Public Objects\Metrics\Count Metrics" HIDDEN FALSE ON PROJECT "MT";',
    "alter_metric"
);

is(
    $foo->alter_object_caching(
        PROJECT           => "MT",
        MAXRAMUSAGE       => 10240,
        MAXRAMUSAGECLIENT => 10240
    ),
'ALTER OBJECT CACHING IN PROJECT "MT" MAXRAMUSAGE 10240 MAXRAMUSAGECLIENT 10240;',
    "alter_object_caching"
);

is(
    $foo->alter_project_ace(
        PROJECT_OBJECT_TYPE      => "REPORT",
        OBJECT_NAME              => "Regional Report",
        LOCATION                 => '\Public Objects\Reports\Regional',
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "jen",
        ACCESSRIGHTS             => "FULLCONTROL",
        PROJECT                  => "MT"
    ),
'ALTER ACE FOR REPORT "Regional Report" IN FOLDER "\Public Objects\Reports\Regional" USER "jen" ACCESSRIGHTS FULLCONTROL FOR PROJECT "MT";',
    "alter_project_ace"
);

is(
    $foo->alter_project_config(
        DESCRIPTION    => "MicroStrategy Tutorial Project",
        WAREHOUSE      => "Tutorial Data",
        STATUS         => "status.html",
        SHOWSTATUS     => "TRUE",
        STATUSONTOP    => "TRUE",
        DOCDIRECTORY   => 'C:\Program Files\MicroStrategy\Tutorial Reporting',
        MAXNOATTRELEMS => 1000,
        USEWHLOGINEXEC => "TRUE",
        ENABLEOBJECTDELETION   => "TRUE",
        MAXREPORTEXECTIME      => 600,
        MAXNOREPORTRESULTROWS  => 64000,
        MAXNOELEMROWS          => 64000,
        MAXNOINTRESULTROWS     => 64000,
        MAXJOBSUSERACCT        => 100,
        MAXJOBSUSERSESSION     => 100,
        MAXEXECJOBSUSER        => 100,
        MAXJOBSPROJECT         => 100,
        MAXUSERSESSIONSPROJECT => 500,
        PROJDRILLMAP =>
          '\Public Objects\Drill Maps\MicroStrategy Tutorial Drill Map',
        DRILLMAP_LOCATION =>
          '\Public Objects\Drill Maps\MicroStrategy Tutorial Drill Map',
        REPORTTPL            => "Default Report",
        REPORTSHOWEMPTYTPL   => "TRUE",
        TEMPLATETPL          => "Default Template",
        TEMPLATESHOWEMPTYTPL => "TRUE",
        METRICTPL            => "Default Metric",
        METRICSHOWEMPTYTPL   => "TRUE",
        PROJECT              => "MT"
    ),
'ALTER PROJECT CONFIGURATION DESCRIPTION "MicroStrategy Tutorial Project" WAREHOUSE "Tutorial Data" STATUS "status.html" SHOWSTATUS TRUE STATUSONTOP TRUE DOCDIRECTORY "C:\Program Files\MicroStrategy\Tutorial Reporting" MAXNOATTRELEMS 1000 USEWHLOGINEXEC TRUE ENABLEOBJECTDELETION TRUE MAXREPORTEXECTIME 600 MAXNOREPORTRESULTROWS 64000 MAXNOELEMROWS 64000 MAXNOINTRESULTROWS 64000 MAXJOBSUSERACCT 100 MAXJOBSUSERSESSION 100 MAXEXECJOBSUSER 100 MAXJOBSPROJECT 100 MAXUSERSESSIONSPROJECT 500 PROJDRILLMAP "\Public Objects\Drill Maps\MicroStrategy Tutorial Drill Map" IN FOLDER "\Public Objects\Drill Maps\MicroStrategy Tutorial Drill Map" REPORTTPL "Default Report" REPORTSHOWEMPTYTPL TRUE TEMPLATETPL "Default Template" TEMPLATESHOWEMPTYTPL TRUE METRICTPL "Default Metric" METRICSHOWEMPTYTPL TRUE IN PROJECT "MT";',
    "alter_project_config"
);

is(
    $foo->alter_report(
        REPORT => "Profit Forecast",
        LOCATION =>
'\Public Objects\Reports\Subject Areas\Enterprise Performance Management',
        ENABLECACHE         => "DEFAULT",
        NEW_NAME            => "Copy of Profit Forecast",
        NEW_LONGDESCRIPTION => "This is the Copy of Profit Forecast",
        NEW_DESCRIPTION     => "This is the Copy of Profit Forecast",
        NEW_LOCATION =>
'\Public Objects\Reports\Subject Areas\Enterprise Performance Management\Profit',
        HIDDEN  => "FALSE",
        PROJECT => "MT"
    ),
'ALTER REPORT "Profit Forecast" IN FOLDER "\Public Objects\Reports\Subject Areas\Enterprise Performance Management" ENABLECACHE DEFAULT NAME "Copy of Profit Forecast" LONGDESCRIPTION "This is the Copy of Profit Forecast" DESCRIPTION "This is the Copy of Profit Forecast" FOLDER "\Public Objects\Reports\Subject Areas\Enterprise Performance Management\Profit" HIDDEN FALSE FOR PROJECT "MT";',
    "alter_report"
);

is(
    $foo->alter_report_caching(
        PROJECT                  => "MT",
        ENABLED                  => "ENABLED",
        CACHEFILEDIR             => '.\Caches\RAVALOS4',
        MAXRAMUSAGE              => 10240,
        MAXNOCACHES              => 10000,
        LOADCACHESONSTARTUP      => "TRUE",
        ENABLEPROMPTEDCACHING    => "TRUE",
        ENABLENONPROMPTEDCACHING => "TRUE",
        CREATECACHESPERUSER      => "TRUE",
        CREATECACHESPERDBLOGIN   => "TRUE",
        CREATECACHESPERDBCONN    => "TRUE",
        CACHEEXP                 => "NEVER",
    ),
'ALTER REPORT CACHING IN PROJECT "MT" ENABLED CACHEFILEDIR ".\Caches\RAVALOS4" MAXRAMUSAGE 10240 MAXNOCACHES 10000 LOADCACHESONSTARTUP TRUE ENABLEPROMPTEDCACHING TRUE ENABLENONPROMPTEDCACHING TRUE CREATECACHESPERUSER TRUE CREATECACHESPERDBLOGIN TRUE CREATECACHESPERDBCONN TRUE CACHEEXP NEVER;',
    "alter_report_caching"
);

is(
    $foo->alter_schedule(
        SCHEDULE            => "Schedule1",
        NEW_NAME            => "NewSchedule1",
        DESCRIPTION         => "NewSchedule1 Desc",
        STARTDATE           => '09/10/2002',
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        YEARLY              => "LAST WEDNESDAY OF MAY",
        EXECUTE_TIME_OF_DAY => '15:30',
    ),
'ALTER SCHEDULE "Schedule1" NAME "NewSchedule1" DESCRIPTION "NewSchedule1 Desc" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED YEARLY LAST WEDNESDAY OF MAY EXECUTE 15:30;',
    "alter_schedule1"
);

is(
    $foo->alter_schedule(
        SCHEDULE  => "Database Load",
        STARTDATE => '09/10/2002',
        ENDDATE   => "NEVER",
        TYPE      => "EVENTTRIGGERED",
        EVENTNAME => "Database Load",
    ),
'ALTER SCHEDULE "Database Load" STARTDATE 09/10/2002 ENDDATE NEVER TYPE EVENTTRIGGERED EVENTNAME "Database Load";',
    "alter_schedule2"
);

is(
    $foo->alter_schedule(
        SCHEDULE            => "Schedule3",
        STARTDATE           => '09/10/2002',
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        DAILY               => "EVERY 5 DAYS",
        EXECUTE_TIME_OF_DAY => '10:00',
    ),
'ALTER SCHEDULE "Schedule3" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED DAILY EVERY 5 DAYS EXECUTE 10:00;',
    "alter_schedule3"
);

is(
    $foo->alter_schedule(
        SCHEDULE        => "Schedule4",
        STARTDATE       => '09/10/2002',
        ENDDATE         => "NEVER",
        TYPE            => "TIMETRIGGERED",
        DAILY           => "EVERY WEEKDAY",
        EXECUTE_ALL_DAY => "EVERY 5 MINUTES",
    ),
'ALTER SCHEDULE "Schedule4" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED DAILY EVERY WEEKDAY EXECUTE ALL DAY EVERY 5 MINUTES;',
    "alter_schedule4"
);

is(
    $foo->alter_schedule(
        SCHEDULE            => "Schedule5",
        STARTDATE           => '09/10/2002',
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        WEEKLY              => "EVERY 5 WEEKS ON MONDAY, TUESDAY, WEDNESDAY",
        EXECUTE_TIME_OF_DAY => '18:00',
    ),
'ALTER SCHEDULE "Schedule5" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED WEEKLY EVERY 5 WEEKS ON MONDAY, TUESDAY, WEDNESDAY EXECUTE 18:00;',
    "alter_schedule5"
);

is(
    $foo->alter_schedule(
        SCHEDULE        => "Schedule6",
        STARTDATE       => '09/10/2002',
        ENDDATE         => '09/27/02',
        TYPE            => "TIMETRIGGERED",
        MONTHLY         => "DAY 3 OF EVERY 5 MONTHS",
        EXECUTE_ALL_DAY => "EVERY 5 HOURS START AFTER MIDNIGHT 10 MINUTES",
    ),
'ALTER SCHEDULE "Schedule6" STARTDATE 09/10/2002 ENDDATE 09/27/02 TYPE TIMETRIGGERED MONTHLY DAY 3 OF EVERY 5 MONTHS EXECUTE ALL DAY EVERY 5 HOURS START AFTER MIDNIGHT 10 MINUTES;',
    "alter_schedule6"
);

is(
    $foo->alter_schedule(
        SCHEDULE            => "Schedule7",
        STARTDATE           => '09/10/2002',
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        MONTHLY             => "FIRST THURSDAY OF EVERY 10 MONTHS",
        EXECUTE_TIME_OF_DAY => "13:00",
    ),
'ALTER SCHEDULE "Schedule7" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED MONTHLY FIRST THURSDAY OF EVERY 10 MONTHS EXECUTE 13:00;',
    "alter_schedule7"
);

is(
    $foo->alter_schedule(
        SCHEDULE            => "Schedule8",
        STARTDATE           => '09/10/2002',
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        YEARLY              => "MARCH 10",
        EXECUTE_TIME_OF_DAY => "17:00",
    ),
'ALTER SCHEDULE "Schedule8" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED YEARLY MARCH 10 EXECUTE 17:00;',
    "alter_schedule8"
);

is(
    $foo->alter_schedule(
        SCHEDULE            => "Schedule9",
        STARTDATE           => "09/10/2002",
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        YEARLY              => "SECOND SATURDAY OF MAY",
        EXECUTE_TIME_OF_DAY => "09:00",
    ),
'ALTER SCHEDULE "Schedule9" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED YEARLY SECOND SATURDAY OF MAY EXECUTE 09:00;',
    "alter_schedule9"
);

is(
    $foo->alter_security_filter(
        SECURITY_FILTER => "SecFilter1",
        PROJECT         => "MicroStrategy Tutorial",
        FILTER          => "Western United States Customers",
    ),
'ALTER SECURITY FILTER "SecFilter1" IN PROJECT "MicroStrategy Tutorial" FILTER "Western United States Customers";',
    "alter_security_filter1"
);

is(
    $foo->alter_security_filter(
        SECURITY_FILTER => "SecFilter2",
        PROJECT         => "MicroStrategy Tutorial",
        EXPRESSION      => 'Region@ID=3'
    ),
'ALTER SECURITY FILTER "SecFilter2" IN PROJECT "MicroStrategy Tutorial" EXPRESSION "Region@ID=3";',
    "alter_security_filter2"
);

is(
    $foo->alter_security_filter(
        SECURITY_FILTER       => "SecFilter3",
        LOCATION              => '\Public Objects\Filters',
        HIDDEN                => "FALSE",
        PROJECT               => "MicroStrategy Tutorial",
        NEW_NAME              => "Security Filter 3",
        FILTER                => "Western United States Customers",
        FILTER_LOCATION       => '\Public Objects\Filters',
        EXPRESSION            => 'Region@ID=3',
        TOP_ATTRIBUTE_LIST    => [ "Western Region1", "Western Region2" ],
        BOTTOM_ATTRIBUTE_LIST => [ "Profit", "Cost" ]
    ),
'ALTER SECURITY FILTER "SecFilter3" FOLDER "\Public Objects\Filters" HIDDEN FALSE IN PROJECT "MicroStrategy Tutorial" NAME "Security Filter 3" FILTER "Western United States Customers" IN FOLDER "\Public Objects\Filters" EXPRESSION "Region@ID=3" TOP ATTRIBUTE LIST "Western Region1", "Western Region2" BOTTOM ATTRIBUTE LIST "Profit", "Cost";',
    "alter_security_filter3"
);

is(
    $foo->alter_security_role(
        SECURITY_ROLE => "FIS Power Users",
        NAME          => "Finance Power Users",
        DESCRIPTION   => "Finance Power Users"
    ),
'ALTER SECURITY ROLE "FIS Power Users" NAME "Finance Power Users" DESCRIPTION "Finance Power Users";',
    "alter_security_role"
);

is(

    $foo->alter_server_config(
        DESCRIPTION              => "Test description",
        MAXCONNECTIONTHREADS     => 100,
        BACKUPFREQ               => 200,
        USEPERFORMANCEMON        => "TRUE",
        USEMSTRSCHEDULER         => "TRUE",
        SCHEDULERTIMEOUT         => 300,
        BALSERVERTHREADS         => "TRUE",
        CACHECLEANUPFREQ         => 400,
        LICENSECHECKTIME         => "23:00",
        HISTORYDIR               => '.\INBOX\dsmith',
        MAXNOMESSAGES            => 500,
        MESSAGELIFETIME          => 600,
        MAXNOJOBS                => 700,
        MAXNOCLIENTCONNS         => 800,
        IDLETIME                 => 900,
        WEBIDLETIME              => 1000,
        MAXNOXMLCELLS            => 1100,
        MAXNOXMLDRILLPATHS       => 5,
        MAXMEMXML                => 1200,
        MAXMEMPDF                => 1300,
        MAXMEMEXCEL              => 1400,
        ENABLEWEBTHROTTLING      => "TRUE",
        MAXMEMUSAGE              => "95",
        MINFREEMEM               => "95",
        ENABLEMEMALLOC           => "TRUE",
        MAXALLOCSIZE             => 1700,
        ENABLEMEMCONTRACT        => "TRUE",
        MINRESERVEDMEM           => 95,
        MINRESERVEDMEMPERCENTAGE => "95",
        MAXVIRTUALADDRSPACE      => "95",
        MEMIDLETIME              => 90,
        WORKSETDIR               => '.\INBOX\dsmith',
        MAXRAMWORKSET            => 1600
    ),
'ALTER SERVER CONFIGURATION DESCRIPTION "Test description" MAXCONNECTIONTHREADS 100 BACKUPFREQ 200 USEPERFORMANCEMON TRUE USEMSTRSCHEDULER TRUE SCHEDULERTIMEOUT 300 BALSERVERTHREADS TRUE CACHECLEANUPFREQ 400 LICENSECHECKTIME 23:00 HISTORYDIR ".\INBOX\dsmith" MAXNOMESSAGES 500 MESSAGELIFETIME 600 MAXNOJOBS 700 MAXNOCLIENTCONNS 800 IDLETIME 900 WEBIDLETIME 1000 MAXNOXMLCELLS 1100 MAXNOXMLDRILLPATHS 5 MAXMEMXML 1200 MAXMEMPDF 1300 MAXMEMEXCEL 1400 ENABLEWEBTHROTTLING TRUE MAXMEMUSAGE 95 MINFREEMEM 95 ENABLEMEMALLOC TRUE MAXALLOCSIZE 1700 ENABLEMEMCONTRACT TRUE MINRESERVEDMEM 95 MINRESERVEDMEMPERCENTAGE 95 MAXVIRTUALADDRSPACE 95 MEMIDLETIME 90 WORKSETDIR ".\INBOX\dsmith" MAXRAMWORKSET 1600;',
    "alter_server_config"
);

is(
    $foo->alter_shortcut(
        LOCATION              => '\Public Objects',
        PROJECT_CONFIG_OBJECT => "FOLDER",
        NAME                  => "Drill Maps",
        NEW_LOCATION          => '\Project Objects',
        PROJECT               => "MicroStrategy Tutorial"
    ),
'ALTER SHORTCUT IN FOLDER "\Public Objects" FOR FOLDER "Drill Maps" FOLDER "\Project Objects" FOR PROJECT "MicroStrategy Tutorial";',
    "alter_shortcut"
);

is(
    $foo->alter_statistics(
        DBINSTANCE      => "Tutorial Data",
        ENABLED         => "ENABLED",
        USERSESSIONS    => "TRUE",
        PROJECTSESSIONS => "TRUE",
        BASICDOCJOBS    => "TRUE",
        DETAILEDDOCJOBS => "TRUE",
        BASICREPJOBS    => "TRUE",
        CACHES          => "TRUE",
        SCHEDULES       => "TRUE",
        COLUMNSTABLES   => "TRUE",
        DETAILEDREPJOBS => "TRUE",
        JOBSQL          => "TRUE",
        SECFILTERS      => "TRUE",
        PROJECT         => "MT"
    ),
'ALTER STATISTICS DBINSTANCE "Tutorial Data" ENABLED USERSESSIONS TRUE PROJECTSESSIONS TRUE BASICDOCJOBS TRUE DETAILEDDOCJOBS TRUE BASICREPJOBS TRUE CACHES TRUE SCHEDULES TRUE COLUMNSTABLES TRUE DETAILEDREPJOBS TRUE JOBSQL TRUE SECFILTERS TRUE IN PROJECT "MT";',
    "alter_statistics"
);

is(
    $foo->alter_table(
        TABLE               => "DT_QUARTER",
        NEW_NAME            => "2",
        NEW_DESCRIPTION     => "1",
        NEW_LOCATION        => '\Schema Objects\Tables\New Tables',
        HIDDEN              => "FALSE",
        LOGICALSIZE         => 10,
        PRESERVELOGICALSIZE => "TRUE",
        PROJECT             => "MT"
    ),
'ALTER TABLE "DT_QUARTER" NAME "2" DESCRIPTION "1" FOLDER "\Schema Objects\Tables\New Tables" HIDDEN FALSE LOGICALSIZE 10 PRESERVELOGICALSIZE TRUE FOR PROJECT "MT";',
    "alter_table"
);

is(
    $foo->alter_user(
        USER            => "jen",
        NAME            => "jenny",
        NTLINK          => "jsmith",
        PASSWORD        => "abc123",
        FULLNAME        => "Jenny Smith",
        DESCRIPTION     => "Test user",
        LDAPLINK        => "jsmith",
        WHLINK          => "PROD_WH",
        WHPASSWORD      => "xyz987",
        ALLOWCHANGEPWD  => "TRUE",
        ALLOWSTDAUTH    => "TRUE",
        CHANGEPWD       => "TRUE",
        PASSWORDEXP     => "IN 60 DAYS",
        PASSWORDEXPFREQ => "60 DAYS",
        ENABLED         => "ENABLED",
        GROUP           => "Test_users"
    ),
'ALTER USER "jen" NAME "jenny" NTLINK "jsmith" PASSWORD "abc123" FULLNAME "Jenny Smith" DESCRIPTION "Test user" LDAPLINK "jsmith" WHLINK "PROD_WH" WHPASSWORD "xyz987" ALLOWCHANGEPWD TRUE ALLOWSTDAUTH TRUE CHANGEPWD TRUE PASSWORDEXP IN 60 DAYS PASSWORDEXPFREQ 60 DAYS ENABLED IN GROUP "Test_users";',
    "alter_user"
);

is(
    $foo->alter_user_group(
        USER_GROUP   => "UAT Users",
        NEW_NAME     => "UAT Testers",
        DESCRIPTION  => "User Acceptance Testers",
        LDAPLINK     => "UAT Testers",
        MEMBERS      => [ "jen1", "jen2" ],
        PARENT_GROUP => "Testers"
    ),
'ALTER USER GROUP "UAT Users" NAME "UAT Testers" DESCRIPTION "User Acceptance Testers" LDAPLINK "UAT Testers" MEMBERS "jen1", "jen2" GROUP "Testers";',
    "alter_user_group"
);

is(
    $foo->alter_users(
        USER_GROUP      => "Managers",
        PASSWORD        => "test",
        CHANGEPWD       => "TRUE",
        PASSWORDEXP     => "IN 5 DAYS",
        PASSWORDEXPFREQ => "90 DAYS",
    ),
'ALTER USERS IN USER GROUP "Managers" PASSWORD "test" CHANGEPWD TRUE PASSWORDEXP IN 5 DAYS PASSWORDEXPFREQ 90 DAYS;',
    "alter_users"
);

