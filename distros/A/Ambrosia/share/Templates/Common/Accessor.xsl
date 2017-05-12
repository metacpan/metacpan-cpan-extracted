<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ambr="app://Ambrosia/EntityDataModel/2011/V1"
    extension-element-prefixes="ambr">

<xsl:output method="text" indent="yes"  />

<xsl:include href="../incName.xsl" />

<xsl:template match="/">
package <xsl:value-of select="$RealAppName" />::Accessor;
use strict;
use warnings;

use Ambrosia::Config;
use Ambrosia::Addons::Session;
use Ambrosia::Meta;

class sealed
{
    extends => [qw/Ambrosia::Addons::Accessor/],
};

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

sub get_access_key_name
{
    return 'authorize_' . config->ID;
}

sub exit
{
    my $self = shift;
    session->deleteItem( $self->get_access_key_name() );
    session->addItem( $self->get_access_key_name() => '' );
}

sub remember_authorize_info
{
    my $self = shift;
    my $login = shift;
    my $password = shift;

    if ( $login &amp;&amp; $password )
    {
        my $crypt_password = crypt($password, $login . $password . $$ . time);
        session->addItem( $self->get_access_key_name() =>
                          {login => $login, password => $crypt_password} );
        return 1;
    }
    return 0;
}

1;
</xsl:template>

</xsl:stylesheet>
