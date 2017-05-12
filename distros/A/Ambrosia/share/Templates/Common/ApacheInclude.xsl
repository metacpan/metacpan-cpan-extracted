<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xsl:output method="text" indent="yes" />

<xsl:include href="../incName.xsl" />

<xsl:template match="/">

Listen <xsl:choose
        ><xsl:when test="boolean(atns:Application/atns:Host/@ServerPort)"
            ><xsl:value-of select="atns:Application/atns:Host/@ServerPort"/></xsl:when
        ><xsl:otherwise>80</xsl:otherwise></xsl:choose>

&lt;VirtualHost *:<xsl:value-of select="atns:Application/atns:Host/@ServerPort"/>>
    ServerAdmin webmaster@<xsl:value-of select="atns:Application/atns:Host/@ServerName"/>
    DocumentRoot <xsl:value-of select="atns:Application/atns:Host/@ProjectPath"/>/<xsl:value-of select="$RealAppName" />/htdocs
    ServerName <xsl:value-of select="atns:Application/atns:Host/@ServerName"/>
    ErrorLog <xsl:value-of select="atns:Application/atns:Host/@ProjectPath"/>/<xsl:value-of select="$RealAppName" />/apache_logs/<xsl:value-of select="$RealAppName" />-error_log
    CustomLog <xsl:value-of select="atns:Application/atns:Host/@ProjectPath"/>/<xsl:value-of select="$RealAppName" />/apache_logs/<xsl:value-of select="$RealAppName" />-access_log common

    &lt;Directory "<xsl:value-of select="atns:Application/atns:Host/@ProjectPath"/>/<xsl:value-of select="$RealAppName" />/htdocs">
        Options Indexes FollowSymLinks MultiViews
        AllowOverride None
        Order allow,deny
        Allow from all
    &lt;/Directory>

    &lt;IfModule mod_perl.c>
        PerlSetEnv  <xsl:value-of select="$UcAppName" />_ROOT <xsl:value-of select="atns:Application/atns:Host/@ProjectPath" />
        PerlSetEnv  <xsl:value-of select="$UcAppName" />_MODE <xsl:value-of select="atns:Application/atns:Host/@Name" />

        <xsl:if test="boolean(atns:Application/atns:Host/@PerlLibPath)">
        #sometimes it not work correctly
        #PerlSetEnv PERL5LIB <xsl:value-of select="translate(atns:Application/atns:Host/@PerlLibPath, ' ', ':')"></xsl:value-of>:<xsl:value-of select="atns:Application/atns:Host/@ProjectPath"/>
        </xsl:if>

        &lt;Perl>
            use lib qw(<xsl:value-of select="atns:Application/atns:Host/@PerlLibPath"
                        /><xsl:text> </xsl:text
                        ><xsl:value-of select="atns:Application/atns:Host/@ProjectPath"/>);

            $ENV{PATH} = "/usr/local/bin:/usr/bin:/bin";
            delete @ENV{qw(IFS CDPATH ENV BASH_ENV)}; 

            use Ambrosia::Config;

            my $rootPath = ($ENV{<xsl:value-of select="$UcAppName" />_ROOT} || '') . '/<xsl:value-of select="$RealAppName" />';

            instance Ambrosia::Config(<xsl:value-of select="$RealAppName" /> => $rootPath . '/Config/<xsl:value-of select="$RealAppName" />.conf');
            config('<xsl:value-of select="$RealAppName" />')->root_path = $rootPath;

            use Ambrosia::Logger;
            instance Ambrosia::Logger('<xsl:value-of select="$RealAppName" />', DEBUG => 1, INFO_EX => 1, INFO => 1, -prefix => '<xsl:value-of select="$RealAppName" />_', -dir => config('<xsl:value-of select="$RealAppName" />')->logger_path);
        &lt;/Perl>

        &lt;LocationMatch "^/<xsl:value-of select="$RealAppName" />ServiceHandler">
            SetHandler  perl-script
            PerlHandler <xsl:value-of select="$RealAppName" />::<xsl:value-of select="$RealAppName" />ServiceHandler
        &lt;/LocationMatch>

        &lt;LocationMatch "^/<xsl:value-of select="$RealAppName" />">
            SetHandler  perl-script
            PerlHandler <xsl:value-of select="$RealAppName" />::<xsl:value-of select="$RealAppName" />
        &lt;/LocationMatch>
    &lt;/IfModule>
&lt;/VirtualHost>

</xsl:template>
</xsl:stylesheet>
