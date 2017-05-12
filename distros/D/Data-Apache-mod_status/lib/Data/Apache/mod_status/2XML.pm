package Data::Apache::mod_status::2XML;

=head1 NAME

Data::Apache::mod_status::LinesXSLT - xslt to transform apache mod status page to xml file

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use warnings;
use strict;

our $VERSION = '0.02';

use FindBin '$Bin';

=head1 METHODS

=head2 xslt()

=cut

sub xslt {
    my $class = shift;
    
    my $mod_status_xslt = <<'__mod_status2xml_xslt__';
<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:x="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="x"
>

<xsl:output
    method="xml"
    version="1.0"
    encoding="UTF-8"

    indent="yes"
/>

<xsl:template match="/">
    <mod_status>
        <info_lines>
            <xsl:for-each select="/x:html/x:body/x:dl/x:dt">
                <line><xsl:value-of select="text()" /></line>
            </xsl:for-each>
        </info_lines>
        <workers>
            <!-- count number of status characters in workers pre tag -->
            <xsl:variable name="workers" select="/x:html/x:body/x:pre[1]/text()" />
            <waiting><xsl:value-of select="string-length(translate($workers, translate($workers, '_', ''), ''))" /></waiting>
            <starting><xsl:value-of select="string-length(translate($workers, translate($workers, 'S', ''), ''))" /></starting>
            <reading><xsl:value-of select="string-length(translate($workers, translate($workers, 'R', ''), ''))" /></reading>
            <sending><xsl:value-of select="string-length(translate($workers, translate($workers, 'W', ''), ''))" /></sending>
            <keepalive><xsl:value-of select="string-length(translate($workers, translate($workers, 'K', ''), ''))" /></keepalive>
            <dns_lookup><xsl:value-of select="string-length(translate($workers, translate($workers, 'D', ''), ''))" /></dns_lookup>
            <closing><xsl:value-of select="string-length(translate($workers, translate($workers, 'C', ''), ''))" /></closing>
            <logging><xsl:value-of select="string-length(translate($workers, translate($workers, 'L', ''), ''))" /></logging>
            <finishing><xsl:value-of select="string-length(translate($workers, translate($workers, 'G', ''), ''))" /></finishing>
            <idle_cleanup><xsl:value-of select="string-length(translate($workers, translate($workers, 'I', ''), ''))" /></idle_cleanup>
            <open_slot><xsl:value-of select="string-length(translate($workers, translate($workers, '.', ''), ''))" /></open_slot>
        </workers>
    </mod_status>
</xsl:template>

</xsl:stylesheet>
__mod_status2xml_xslt__

    # if running tests, developing read the xslt from file located in the root in xslt/ folder
    if (not $mod_status_xslt) {
        eval 'use File::Slurp;';
        $mod_status_xslt = read_file($Bin.'/../xslt/mod_status2xml.xslt');
    }
    
    return $mod_status_xslt;
}

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
