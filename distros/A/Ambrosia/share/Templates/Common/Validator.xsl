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

<xsl:template match="atns:Application/atns:Entity"><xsl:variable name="type" select="translate(@Type, $vLowercaseChars_CONST, $vUppercaseChars_CONST)"/>
package <xsl:value-of select="$RealAppName" />::Validators::<xsl:value-of select="@Name"/>Validator;
use strict;
use warnings;

use Ambrosia::Context;
use Ambrosia::Validator;
require <xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="@Name"/>;

use Ambrosia::Meta;

class
{
    extends => [qw/Ambrosia::Validator/],
};

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

sub prepare_validate
{
    my $self = shift;

    $self->validate(
        <xsl:for-each select="atns:Field">
        <xsl:value-of select="@Name" /> => {
            value => (Ambrosia::Validator::get_value(Context->param(qw/<xsl:value-of select="@Name" />/)))[0] || undef,
        },
        </xsl:for-each>);
}

1;
</xsl:template>

</xsl:stylesheet>
