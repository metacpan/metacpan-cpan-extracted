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

<xsl:template match="atns:Application/atns:Entity">package <xsl:value-of select="$RealAppName" />::Managers::<xsl:value-of select="@Name"/>EditManager;
<xsl:variable name="EId" select="@Id" />
use strict;
use warnings;

use Ambrosia::core::Nil;
use Ambrosia::Context;
require <xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="@Name"/>;

use Ambrosia::Meta;
class
{
    extends => [qw/<xsl:value-of select="$RealAppName" />::Managers::BaseManager/]
};

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

sub prepare
{
    Context->repository->put(
        <xsl:value-of select="@Name"/> => deferred::call {(
                <xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="@Name"/>->load(
                    <xsl:choose><xsl:when test="atns:Key/@AutoUniqueValue">Context->resource_id</xsl:when><xsl:otherwise>
[<xsl:for-each select="atns:Key/atns:FieldRef">Context->param('<xsl:value-of select="@Name" />')||undef, </xsl:for-each>]</xsl:otherwise></xsl:choose>
                    ) || new Ambrosia::core::Nil)->as_hash(0, qw/<xsl:apply-templates select="//atns:Relations/atns:Relation[@RefId=$EId]/atns:EntityRef" mode="link"/>/)
            } );
}

1;
</xsl:template>

<xsl:template match="atns:EntityRef" mode="link">
<xsl:variable name="ref_id" select="@RefId"/>
<xsl:if test="boolean(/atns:Application/atns:EntitysRef/atns:Entity[@Id=$ref_id]/@Type='TABLE')"><xsl:if test="position()>1"><xsl:text> </xsl:text></xsl:if><xsl:value-of select="@Role" /></xsl:if>
</xsl:template>

</xsl:stylesheet>
