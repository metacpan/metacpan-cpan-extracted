<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ambr="app://Ambrosia/EntityDataModel/2011/V1"
    extension-element-prefixes="ambr">

<xsl:output method="text" indent="yes"  />

<xsl:include href="../incName.xsl" />

<xsl:template match="/">package <xsl:value-of select="$RealAppName" />::Managers::AuthorizeManager;
use strict;
use warnings;

use Ambrosia::Meta;
class
{
    extends => [qw/Ambrosia::BaseManager/]
};

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

#sub prepare
#{
#}

1;
</xsl:template>

</xsl:stylesheet>
