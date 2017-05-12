<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xsl:output method="text" indent="yes" />

<xsl:include href="../incName.xsl" />

<!-- Root -->
<xsl:template match="/">
<xsl:apply-templates />
</xsl:template>

<!-- Entity -->
<xsl:template match="/">
package <xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="$RealAppName" />SysUser;
use strict;
use warnings;

use Ambrosia::Meta;
class sealed 
{
    public  => [qw/Password Levels/],
};

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

1;
</xsl:template>
</xsl:stylesheet>