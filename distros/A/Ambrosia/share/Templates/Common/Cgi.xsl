<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xsl:output method="text" indent="yes"  />

<xsl:include href="../incName.xsl" />

<xsl:template match="/">#!/usr/bin/perl
use strict;
use warnings;

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

BEGIN
{
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
};

use <xsl:value-of select="$RealAppName" />::<xsl:value-of select="$RealAppName" />;
<xsl:value-of select="$RealAppName" />::<xsl:value-of select="$RealAppName" />::handler();

</xsl:template>
</xsl:stylesheet>
