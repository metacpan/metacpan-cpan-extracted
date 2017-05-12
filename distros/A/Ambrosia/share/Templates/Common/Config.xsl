<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xsl:output method="text" indent="yes" />

<xsl:include href="../incName.xsl" />

<xsl:template match="/">#!/usr/bin/perl
use strict;
<xsl:apply-templates />
</xsl:template>

<xsl:template match="atns:Application">
our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

my $LEVEL = $ENV{<xsl:value-of select="$UcAppName"/>_MODE};

my ( $ROOT, $DEBUG, $SITE_URL, $LIB_PATH, $PROXY,
<xsl:for-each select="/atns:Application/atns:DataSource/atns:Type/atns:Source">
    $DS_NAME_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
    $DS_ENGINE_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
    <xsl:if test="boolean(@Catalog)">$DS_CATALOG_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,</xsl:if>
    $DS_SCHEMA_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
    $DS_USER_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
    $DS_PASSWORD_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
    $DS_CHARSET_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
    $DS_PARAMS_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
</xsl:for-each>
);

for ($LEVEL)
{
    <xsl:for-each select="atns:Config/atns:Host">
    /^<xsl:value-of select="@Name" />$/ &amp;&amp; do {
        $DEBUG    = '<xsl:value-of select="@Debug" />';
        $ROOT     = '<xsl:value-of select="@ProjectPath" />';
        $SITE_URL = 'http://<xsl:value-of select="@ServerName" /><xsl:if test="boolean(@ServerPort)">:<xsl:value-of select="@ServerPort" /></xsl:if>';
        $PROXY    = undef;
        $LIB_PATH = '<xsl:value-of select="@PerlLibPath" /><xsl:text> </xsl:text><xsl:value-of select="@PerlLibPath" />';
<xsl:for-each select="/atns:Application/atns:DataSource/atns:Type/atns:Source">
        $DS_NAME_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/> = '<xsl:value-of select="@Name"/>';
        $DS_ENGINE_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/> = '<xsl:value-of select="@Engine"/>';
        <xsl:if test="boolean(@Catalog)">$DS_CATALOG_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/> = '<xsl:value-of select="@Catalog"/>';</xsl:if>
        $DS_SCHEMA_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/> = '<xsl:value-of select="@Schema"/>';
        $DS_USER_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/> = '<xsl:value-of select="@User"/>';
        $DS_PASSWORD_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/> = '<xsl:value-of select="@Password"/>';
        $DS_CHARSET_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/> = '<xsl:value-of select="@Charset"/>';
        $DS_PARAMS_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/> = '<xsl:value-of select="@Params"/>';
</xsl:for-each>
        1;
    } ||
    </xsl:for-each>
    die "Unknown level in config file: $LEVEL";
}

my $TPL_DIR = "$ROOT/<xsl:value-of select="@Name"/>/Templates";
my $LOG_DIR = "$ROOT/app_log/";

my $OPEN_ACCESS = 0;
my $AUTHORIZE_ACCESS = -1;
<xsl:for-each select="atns:Entitys/atns:Entity">
<xsl:variable name="type" select="translate(@Type, $vLowercaseChars_CONST, $vUppercaseChars_CONST)"/><xsl:if test="$type='TABLE' or $type='TREE'">
my $EDIT_<xsl:value-of select="@Name"/> = <xsl:value-of select="position()*2-1"/>;</xsl:if><xsl:if test="$type!='ABSTRACT' and $type!='BIND'">
my $VIEW_<xsl:value-of select="@Name"/> = <xsl:value-of select="position()*2"/>;
</xsl:if></xsl:for-each>

return
{
    ID       => '<xsl:value-of select="$UcAppName"/>',
    LABEL    => '<xsl:value-of select="@Label"/>',
    Charset  => '<xsl:value-of select="@Charset"/>',
    ROOT     => $ROOT,
    DEBUG    => $DEBUG,

    #The root directory that is defined in the main module
    root_path => undef,

    #The path to log file.
    logger_path => $LOG_DIR,

    template_path => $TPL_DIR,

    template_web_path => $SITE_URL . '/Templates_<xsl:value-of select="$UcAppName"/>',


    MANAGERS => {
        #manager that returns the main page
        '*' => {
            manager  => '<xsl:value-of select="@Name"/>::Managers::MainManager',
            template => 'main.xsl',
            access   => $AUTHORIZE_ACCESS
        },
        '/list' => {
            manager => '<xsl:value-of select="@Name"/>::Managers::ListManager',
            template => 'list_json.xsl',
            access   => $OPEN_ACCESS
        },
        <xsl:if test="/atns:Application/@Authorization!='NO'">
        '/authorize' => {
            manager => '<xsl:value-of select="@Name"/>::Managers::AuthorizeManager',
            template => 'authorize.xsl',
            access   => $OPEN_ACCESS
        },
        '/exit' => {
            manager  => '<xsl:value-of select="@Name"/>::Managers::ExitManager',
            #template => 'authorize.xsl',
            access   => $OPEN_ACCESS
        },
        </xsl:if>
<xsl:if test="boolean(./atns:Entitys/atns:Entity[@Type='TREE'])">
        '/tree' => {
            manager => '<xsl:value-of select="@Name"/>::Managers::ListManager',
            template => 'tree_json.xsl',
            access   => $OPEN_ACCESS
        },
</xsl:if>

<xsl:text>
</xsl:text>
    <xsl:for-each select="./atns:Entitys/atns:Entity">
        <xsl:variable name="entityName" select="translate(@Name, $vUppercaseChars_CONST, $vLowercaseChars_CONST)"/>
        <xsl:variable name="typeEntity" select="translate(@Type, $vLowercaseChars_CONST, $vUppercaseChars_CONST)"/>
        <xsl:if test="$typeEntity='TABLE' or $typeEntity='TREE'">
        '/get/<xsl:value-of select="$entityName"/>' => {
            manager  => '<xsl:value-of select="../../@Name"/>::Managers::<xsl:value-of select="@Name"/>EditManager',
            template => '<xsl:value-of select="$entityName"/>_edit_json.xsl',
            access   => $EDIT_<xsl:value-of select="@Name"/>
        },
        '/save/<xsl:value-of select="$entityName"/>' => {
            manager  => '<xsl:value-of select="../../@Name"/>::Managers::<xsl:value-of select="@Name"/>SaveManager',
            access   => $EDIT_<xsl:value-of select="@Name"/>
        },
        </xsl:if>
        <xsl:if test="$typeEntity!='ABSTRACT' and $typeEntity!='BIND' and $typeEntity!='TREE'">
        '/list/<xsl:value-of select="$entityName"/>' => {
            manager => '<xsl:value-of select="../../@Name"/>::Managers::<xsl:value-of select="@Name"/>ListManager',
            access   => $VIEW_<xsl:value-of select="@Name"/>
        },
        </xsl:if>
        <xsl:if test="$typeEntity='TREE'">
        '/list/<xsl:value-of select="$entityName"/>' => {
            manager => '<xsl:value-of select="../../@Name"/>::Managers::<xsl:value-of select="@Name"/>TreeManager',
            access   => $VIEW_<xsl:value-of select="@Name"/>
        },
        </xsl:if>
        <xsl:text>
        </xsl:text>
    </xsl:for-each>
    },

    CommonGatewayInterface => {
        engine_name   => '<xsl:value-of select="/atns:Application/atns:Config/atns:CommonGatewayInterface/@Engine" />',
        engine_params => {
            header_params => {
                <xsl:for-each select="/atns:Application/atns:Config/atns:CommonGatewayInterface/atns:Params/@*">
                    <xsl:value-of select="name()" /> => '<xsl:value-of select="." />',
            </xsl:for-each>},
        },
        proxy         => $PROXY,
    },

    data_source => {
        <xsl:for-each select="/atns:Application/atns:DataSource/atns:Type">
        <xsl:value-of select="@Name" /> => [<xsl:for-each select="atns:Source">{
            source_name   => $DS_NAME_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
            engine_name   => $DS_ENGINE_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
            <xsl:if test="boolean(@Catalog)">catalog       => $DS_CATALOG_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,</xsl:if>
            schema        => $DS_SCHEMA_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
            user          => $DS_USER_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
            password      => $DS_PASSWORD_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
            engine_params => $DS_PARAMS_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>,
            additional_params => { AutoCommit => 0, RaiseError => 1, LongTruncOk => 1 },
            additional_action => sub { my $dbh = shift; $dbh->do("SET NAMES $DS_CHARSET_<xsl:value-of select="../@Name"/>_<xsl:value-of select="@Name"/>")},
        },</xsl:for-each>],</xsl:for-each>
    },

#delete this block if your application don't use remoute services or change it
    service_conf => {
        'SOAP::Lite' => [
                {
                    name => '<xsl:value-of select="$RealAppName"/>',
                    __proxy => 'uri of calling service',
                    __outputxml => 'false',
                    __readable => 0,
                    __default_ns => 'urn:<xsl:value-of select="$RealAppName"/>/<xsl:value-of select="$RealAppName"/>Services',
                    #__ns => 'urn:<xsl:value-of select="$RealAppName"/>/<xsl:value-of select="$RealAppName"/>Services',
                    __soapversion => '1.2',
                    __timeout => undef,
                    #__on_error #you can use `on_error(sub{})` method of Ambrosia::RPC::Service::SOAP::Lite
                },
            ],
    },

    NUMBER_PER_PAGE => 20,

<xsl:if test="/atns:Application/@Authorization!='NO'">
    login => 'god',
    password => 'fv,hjpbz',

    ACCESS_LEVELS => {
        <xsl:value-of select="$UcAppName"/> => {
            LABEL => '<xsl:value-of select="@Label"/>',
            LEVELS => {<xsl:for-each select="./atns:Entitys/atns:Entity"><xsl:variable name="type" select="translate(@Type, $vLowercaseChars_CONST, $vUppercaseChars_CONST)"/>
<xsl:if test="$type='TABLE'">
                $EDIT_<xsl:value-of select="@Name"/> => 'Edit <xsl:value-of select="@Label" />',</xsl:if><xsl:if test="$type!='ABSTRACT' and $type!='BIND'">
                $VIEW_<xsl:value-of select="@Name"/> => 'View <xsl:value-of select="@Label" />',
</xsl:if></xsl:for-each>
            }
        }
    },
</xsl:if>

};
</xsl:template>

</xsl:stylesheet>
