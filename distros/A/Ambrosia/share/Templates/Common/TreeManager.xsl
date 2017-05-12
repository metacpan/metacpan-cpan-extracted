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

<xsl:template match="atns:Application/atns:Entity">package <xsl:value-of select="$RealAppName" />::Managers::<xsl:value-of select="@Name"/>TreeManager;
use strict;
use JSON::XS;

use Ambrosia::Config;
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
    if ( my $node = <xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="@Name"/>->root() )
    {
        Context->repository->set( response => [
            map {
                {
                    '$ref' => $_->TreeId,
                    $_->Representation(),
                    ($_->have_children() ? (children => JSON::XS::true ) : ())
                };
            } @{$node->load_children()}
        ] );
    }
}

1;
</xsl:template>

</xsl:stylesheet>
