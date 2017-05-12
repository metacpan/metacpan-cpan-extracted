<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xsl:output method="text" indent="yes"  />

<xsl:include href="../incName.xsl" />

<xsl:template match="/">package <xsl:value-of select="$RealAppName" />::Managers::ListManager;
use strict;
use warnings;

use Ambrosia::Context;
use Ambrosia::core::ClassFactory;

use Ambrosia::Meta;
class
{
    extends => [qw/<xsl:value-of select="$RealAppName" />::Managers::BaseManager/]
};

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

sub prepare
{
    my $entity = Context->param('entity');
    Context->repository->set(
        Field   => Ambrosia::core::ClassFactory::load_class($entity)->RepresentationMeta(),
        Name    => lc(( $entity =~ /.+::(.+)$/ )[0]),
        mutable => eval {$entity->mutable()}
    );
}

1;
</xsl:template>

</xsl:stylesheet>
