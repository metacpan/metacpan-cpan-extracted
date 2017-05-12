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
<xsl:template match="atns:Application/atns:Entity">=head1 NAME

Class for mapping entity to data source <xsl:value-of select="concat(@DataSourceNameRef, ':', @SourcePath)"/>.

=cut

package <xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="@Name"/>;
use strict;
use warnings;

use Ambrosia::error::Exceptions;
use Ambrosia::core::Nil;
use Ambrosia::Validator::Constraint;
<xsl:variable name="type" select="translate(@Type, $vLowercaseChars_CONST, $vUppercaseChars_CONST)"/>
use Ambrosia::Meta;
class <xsl:choose>
    <xsl:when test="$type='ABSTRACT'"><xsl:text>abstract</xsl:text></xsl:when>
    <xsl:otherwise><xsl:text>sealed</xsl:text></xsl:otherwise>
</xsl:choose>
{<xsl:variable name="extends" select="@Extends" />
    extends => [qw/<xsl:choose>
    <xsl:when test="$extends!=''"><xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="//EntitysRef/Entity[@Name=$extends]/@Name" /></xsl:when>
    <xsl:when test="$type='TREE'">Ambrosia::Addons::Tree::NodeTree</xsl:when>
    <xsl:otherwise>Ambrosia::EntityDataModel</xsl:otherwise>
</xsl:choose>/],
<!-- Fields of class(fields table in schema) -->
    public  => [qw/
        <xsl:for-each select="atns:Field/@Name">
            <xsl:if test="../../@Type != 'TREE' or (. != 'TreeId' and . != 'ParentId')"><xsl:value-of select="." /><xsl:text>
        </xsl:text></xsl:if></xsl:for-each>/],
};

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

<xsl:if test="@Type='TABLE' or @Type='TREE'">
our %Constraints = (
    <xsl:for-each select="atns:Field">
        <xsl:variable name='name' select="@Name" />
        <xsl:value-of select="$name" /> => Ambrosia::Validator::Constraint->new(name => '<xsl:value-of select="$name" />')
            -><xsl:value-of select="@Type" />(errorMessage => '',)<xsl:if test="@Type='String'">
            ->StringLength(min => undef, max => <xsl:value-of select="@Size" />,errorMessage => '',)
            </xsl:if
        ><xsl:if test="@IsNullable='NO' and ../atns:Key[@AutoUniqueValue='YES']/atns:FieldRef/@Name!=$name"
        >->Require(notEmpty => 1, errorMessage => '',)</xsl:if>,
    </xsl:for-each>);
</xsl:if>

<xsl:if test="@Type='TABLE' or @Type='VIEW'">
sub RepresentationMeta
{
<xsl:variable name="eId" select="/atns:Application/atns:Entity/@Id"/>
    return [<xsl:for-each select="atns:Field"><xsl:variable name='name' select="@Name" />
        {
            label => '<xsl:value-of select="@Label" />',
            <xsl:if test="not(//atns:Relations/atns:Relation/atns:EntityRef[@RefId=$eId and @To=$name])"
                >field => '<xsl:value-of select="$name" />',</xsl:if>
            <xsl:if test="../atns:Key/atns:FieldRef/@Name=$name">key => 1,</xsl:if>
            <xsl:if test="@Hidden='YES'">hidden => 1,</xsl:if>
            <xsl:apply-templates select="//atns:Relations/atns:Relation/atns:EntityRef[@RefId=$eId and @To=$name]" mode="ref" />
        },</xsl:for-each>
    ];
}

sub Representation
{
    my $self = shift;
    my $clean = shift;
    my $level = shift || 0;
    my @res = ();
    my (%h, $f, @values);
    foreach ( @{RepresentationMeta()} )
    {
        next if $clean &amp;&amp; $_->{hidden};
        $f = $_->{field};
        if ( $_->{ref} )
        {
            if ( $_->{ref} ne ref $self || $level == 0 )
            {
                %h = $self->$f->Representation(1, ++$level);
                my $v = join(' ', map {$h{$_}} grep {$_ ne $f} sort keys %h);
                push @res, $f, $v;
                push @values, $v unless $_->{hidden};
            }
        }
        else
        {
            push @res, $f, $self->$f;
            push @values, $self->$f unless $_->{hidden};
        }
    }
    return @res, <xsl:value-of select="@Name"/> => join ' ', @values;
}
</xsl:if>

<xsl:if test="@Type='TREE'">
sub RepresentationMeta
{
    return [
        {
            label => 'id',
            field => 'TreeId',
        },
        {
            label => 'parent',
            field => 'ParentId',
        },
    <xsl:for-each select="atns:Field[@Name!='TreeId' and @Name!='ParentId']"><xsl:variable name='name' select="@Name" />
        {
            label => '<xsl:value-of select="translate($name, $vUppercaseChars_CONST, $vLowercaseChars_CONST)" />',
            <xsl:if test="not(//atns:Relations/atns:Relation/atns:EntityRef[@RefId=/atns:Application/atns:Entity/@Id and @To=$name])">field => '<xsl:value-of select="$name" />',
            </xsl:if>
        },</xsl:for-each>
    ];
}

sub Representation
{
    my $self = shift;
    my @res = ();
    my $f;
    foreach ( @{RepresentationMeta()} )
    {
        $f = $_->{field};
        push @res, $_->{label}, $self->$f;
    }
    return @res;
}
</xsl:if>

sub mutable
{
    1;
}

<xsl:apply-templates select="//atns:Relations" mode="require" />

<xsl:if test="@DataSourceTypeRef!='DBI'">
=head2 driver_type

Return type of driver of data source.

=cut

sub driver_type
{
    return '<xsl:value-of select="@DataSourceTypeRef"/>';
}
</xsl:if>


=head2 source_name

Returned the name of data source.

=cut

sub source_name
{
    return '<xsl:value-of select="@DataSourceNameRef"/>';
}

=head2 table

Returned the name of table.

=cut

sub table
{
    return '<xsl:value-of select="@SourcePath"/>';
}

<xsl:choose>
<xsl:when test="atns:Key/@AutoUniqueValue">
=head2 primary_key

Returned name of primary key that have auto increment.

=cut

sub primary_key
{
    return '<xsl:value-of select="atns:Key/atns:FieldRef/@Name"/>';
}
</xsl:when>
<xsl:otherwise>
=head2 key

Returned the list of key fields.

=cut

sub key
{
    return [<xsl:for-each select="atns:Key/atns:FieldRef">'<xsl:value-of select="@Name" />',</xsl:for-each>];
}
</xsl:otherwise>
</xsl:choose>


<xsl:apply-templates select="//atns:Relations" mode="link" />

<xsl:apply-templates />

1;
</xsl:template>

<xsl:template match="atns:EntityRef" mode="ref">
    field => '<xsl:value-of select="../@Type" />',
    ref => '<xsl:value-of select="$RealAppName" />::Entity::<xsl:value-of select="../@Type" />',
</xsl:template>

<xsl:template match="//atns:Relations" mode="require">
<xsl:variable name="eId" select="/atns:Application/atns:Entity/@Id"/>
<xsl:apply-templates select="atns:Relation[@RefId=$eId]/atns:EntityRef[@RefId=//atns:EntitysRef/atns:Entity/@Id and @RefId != $eId]" mode="require" />
<xsl:apply-templates select="atns:Relation/atns:EntityRef[@RefId=$eId and @Feedback='YES']" mode="require_revers" />
</xsl:template>

<xsl:template match="atns:EntityRef" mode="require">
<xsl:variable name="refId" select="@RefId"/>
require <xsl:value-of select="$RealAppName"
            />::Entity::<xsl:value-of
                        select="//atns:EntitysRef/atns:Entity[@Id=$refId]/@Name" />;</xsl:template>

<xsl:template match="atns:EntityRef" mode="require_revers">
<xsl:variable name="refId" select="../@RefId"/>
require <xsl:value-of select="$RealAppName"
            />::Entity::<xsl:value-of
                        select="//atns:EntitysRef/atns:Entity[@Id=$refId]/@Name" />;</xsl:template>

<xsl:template match="//atns:Relations" mode="link">
<xsl:variable name="eId" select="/atns:Application/atns:Entity/@Id"/>
<xsl:apply-templates select="atns:Relation[@RefId=$eId]/atns:EntityRef[@RefId=//atns:EntitysRef/atns:Entity/@Id and @RefId != $eId]" mode="link" />
<xsl:apply-templates select="atns:Relation/atns:EntityRef[@RefId=$eId and @Feedback='YES']" mode="link_revers" />
</xsl:template>

<xsl:template match="atns:EntityRef" mode="link">
    <xsl:variable name="refId" select="@RefId"/>
    <xsl:variable name="linkProc">
        <xsl:choose>
            <xsl:when test="@Multiplicity='YES'">
                <xsl:text>link_one2many</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>link_one2one</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="optional">
        <xsl:choose>
            <xsl:when test="@Optional='YES'">
                <xsl:text>1</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>0</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
__PACKAGE__-><xsl:value-of select="$linkProc"
                />(name => '<xsl:value-of select="@Role"
                />', type => '<xsl:value-of select="$RealAppName"
                                />::Entity::<xsl:value-of select="//atns:EntitysRef/atns:Entity[@Id=$refId]/@Name"
                />', from => '<xsl:value-of select="@From"
                />', to => '<xsl:value-of select="@To"
                />', optional => <xsl:value-of select="$optional"
                />);</xsl:template>

<xsl:template match="atns:EntityRef" mode="link_revers">
    <xsl:variable name="refId" select="../@RefId"/>
__PACKAGE__->link_one2one(name => '<xsl:value-of select="../@Type"
                />', type => '<xsl:value-of select="$RealAppName"
                                />::Entity::<xsl:value-of select="//atns:EntitysRef/atns:Entity[@Id=$refId]/@Name"
                />', from => '<xsl:value-of select="@To"
                />', to => '<xsl:value-of select="@From"
                />', optional => 0);</xsl:template>

</xsl:stylesheet>
