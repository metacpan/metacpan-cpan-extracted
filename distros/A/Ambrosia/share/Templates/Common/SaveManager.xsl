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

<xsl:template match="atns:Application/atns:Entity">package <xsl:value-of select="$RealAppName" />::Managers::<xsl:value-of select="@Name"/>SaveManager;
use strict;
use warnings;

use Ambrosia::Context;
require <xsl:value-of select="$RealAppName" />::Validators::<xsl:value-of select="@Name"/>Validator;
require <xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="@Name"/>;

use Ambrosia::Meta;
class
{
    extends => [qw/<xsl:value-of select="$RealAppName" />::Managers::BaseManager/]
};

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

sub prepare
{
    my $self = shift;

    eval
    {
        my $validator = new <xsl:value-of select="$RealAppName" />::Validators::<xsl:value-of select="@Name"/>Validator(_prototype => '<xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="@Name"/>');
        if ( my $violations = $validator->verify )
        {
            Context->repository->set(<xsl:value-of select="@Name"/> => $violations);
            $self->add_error($violations, '<xsl:value-of select="@Name"/>');
        }
        else
        {
            Context->repository->set(<xsl:value-of select="@Name"/> => undef);
            $validator->Instance->save;
            $self->add_message('Data saved successfully.');
        }
    };
    if ( $@ )
    {
        $self->add_error($@, '<xsl:value-of select="@Name"/>');
    }

    <xsl:variable name="entityName" select="translate(@Name, $vUppercaseChars_CONST, $vLowercaseChars_CONST)"/>
    $self->relegate('/get/<xsl:value-of select="$entityName"/>');
}

1;
</xsl:template>

</xsl:stylesheet>
