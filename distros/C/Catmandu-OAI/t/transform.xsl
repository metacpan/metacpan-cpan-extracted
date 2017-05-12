<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:e="urn:nbn:de:1111-2004033116">
    <xsl:template match="e:epicur">
        <xsl:element name="{e:administrative_data/e:delivery/e:update_status/@type}">
            <xsl:attribute name="url">
                <xsl:value-of select="e:record/e:resource/e:identifier[@scheme='url' and @role='primary']"/>
            </xsl:attribute>
            <xsl:value-of select="e:record/e:identifier[@scheme='urn:nbn:de']"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
