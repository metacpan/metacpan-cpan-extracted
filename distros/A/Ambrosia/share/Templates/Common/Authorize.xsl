<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ambr="app://Ambrosia/EntityDataModel/2011/V1"
    extension-element-prefixes="ambr">

<xsl:output method="text" indent="yes"  />

<xsl:include href="../incName.xsl" />

<xsl:template match="/">
package <xsl:value-of select="$RealAppName" />::Authorize;
use strict;
use warnings;

use <xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="$RealAppName" />SysUser;
use Ambrosia::core::Nil;
use Ambrosia::Config;

use Ambrosia::Meta;

class sealed
{
    extends => [qw/Ambrosia::Addons::Authorize/],
};

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

sub get
{
    my $self = shift;
    my $login = shift;
    my $level = shift;

    if ( $login eq config->login )
    {
        return new <xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="$RealAppName" />SysUser(
            Password => config->password,
            Levels => [keys %{config->ACCESS_LEVELS->{config->ID}->{LEVELS}}]);
    }

    return new Ambrosia::core::Nil;
}

1;
</xsl:template>

</xsl:stylesheet>

