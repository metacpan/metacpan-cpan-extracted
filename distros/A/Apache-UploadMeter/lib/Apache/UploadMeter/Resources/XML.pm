package Apache::UploadMeter::Resources::XML;

# Static resources (XSL/XSD) for the UploadMeter widget

use strict;
use warnings;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Response ();
use Apache2::Const -compile=>qw(:common);

sub xsl {
    my $r = shift;
    $r->content_type("text/xml; charset=utf-8");
    $r->set_etag();
    return Apache2::Const::OK if $r->header_only();
    my $output=<<'XSL-END';
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="html" indent="yes" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"/>
	<!-- root rule -->
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>
	<!-- main rule for document element -->
	<xsl:template match="APACHE_UPLOADMETER">
		<html>
			<head>
				<title>Downloading <xsl:value-of select="@FILE"/>
				</title>
			</head>
			<body style="background-color: #D0D9DF; text-align: center; margin: 0px 0px 0px 0px;">
				<span style="text-align: center; font-face: Arial; font-size: 12pt;">
					<span style="text-align: center; font-size: 14pt; font-weight: bold;">Apache Upload Meter</span>
					<table width="100%" border="0" cellspacing="5" cellpadding="0">
						<tbody>
							<tr>
								<td width="30%" align="right">Filename:</td>
								<td width="70%" align="left">
									<xsl:value-of select="@FILE"/>
								</td>
							</tr>
							<tr>
								<td align="right">Status:</td>
								<td align="left">
									<xsl:choose>
										<xsl:when test="@FINISHED = 1"><font color="#667799">Transfer complete  (<xsl:value-of select="TOTAL"/>)</font></xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="RECEIVED"/> of <xsl:value-of select="TOTAL"/>
										</xsl:otherwise>
									</xsl:choose>
								</td>
							</tr>
							<tr>
								<td align="right">Elapsed Time:</td>
								<td align="left">
									<xsl:value-of select="ELAPSEDTIME"/>
								</td>
							</tr>
							<tr>
								<td align="right">Remaining Time:</td>
								<td align="left">
								<!--  my $rtime = ($finished) ? 0 : int ($etime / $len * $size) - $etime;-->
<!-- Calculates remaining time, but no formatting available :-(
									<xsl:choose>
										<xsl:when test="@FINISHED = 1">00:00:00</xsl:when>
										<xsl:otherwise>	<xsl:value-of select="((ELAPSEDTIME/@VALUE div RECEIVED/@VALUE) * TOTAL/@VALUE)"/></xsl:otherwise>
									</xsl:choose>-->
									<xsl:value-of select="REMAININGTIME"/>
								</td>
							</tr>
							<tr>
								<td align="right">Rate:</td>
								<td align="left">
									<xsl:value-of select="CURRENTRATE"/> (avg <xsl:value-of select="RATE"/>)</td>
							</tr>
						</tbody>
					</table>
					<br/>
					<xsl:variable name="umwidth" select="400"/>
					<xsl:variable name="received"  select="RECEIVED/@VALUE"/>
					<xsl:variable name="total" select="TOTAL/@VALUE"/>
					<xsl:variable name="percent" select="round($received div $total * 100)"/>
					<xsl:variable name="barwidth" select="round($received div $total * $umwidth)"/>
					<xsl:variable name="leftover" select="$umwidth - $barwidth"/>
					<div align="center">
						<table bgcolor="#667799" border="0" cellpadding="2" cellspacing="0">
							<tbody>
								<tr>
									<td>
										<table border="0" cellpadding="0" cellspacing="0">
											<xsl:attribute name="width"><xsl:value-of select="$umwidth"/></xsl:attribute>
											<tbody>
												<tr>
													<td bgcolor="#667799" height="20">
														<xsl:attribute name="width"><xsl:value-of select="$barwidth"/></xsl:attribute>
													</td>
													<td bgcolor="lightgrey" height="20">
														<xsl:attribute name="width"><xsl:value-of select="$leftover"/></xsl:attribute>
													</td>
												</tr>
											</tbody>
										</table>
									</td>
								</tr>
							</tbody>
						</table>
					</div>
					<span style="font-face: Arial; font-size: 14pt; font-weight: bold;">
						<xsl:value-of select="$percent"/>%</span>
					<br/>
					<xsl:if test="@FINISHED =1">
						<input type="button" name="close" value="Close" onClick="javascript:window.close()"/>
					</xsl:if>
					<br/>
					<br/>
					<br/>
					<br/>
					<br/>
					<br/>
					<br/>
					<br/>
				</span>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
XSL-END
    $r->print($output);
    return Apache2::Const::OK;
}

sub xsd {
    my $r = shift;
    $r->content_type("text/xml; charset=utf-8");
    $r->set_etag();
    return Apache2::Const::OK if $r->header_only();
    my $output=<<'XSD-END';
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
	<xs:element name="APACHE_UPLOADMETER">
		<xs:complexType>
			<xs:sequence>
				<xs:element name="RECEIVED">
					<xs:complexType>
						<xs:simpleContent>
							<xs:extension base="xs:string">
								<xs:attribute name="VALUE" type="xs:positiveInteger" use="required"/>
							</xs:extension>
						</xs:simpleContent>
					</xs:complexType>
				</xs:element>
				<xs:element name="TOTAL">
					<xs:complexType>
						<xs:simpleContent>
							<xs:extension base="xs:string">
								<xs:attribute name="VALUE" type="xs:positiveInteger" use="required"/>
							</xs:extension>
						</xs:simpleContent>
					</xs:complexType>
				</xs:element>
				<xs:element name="ELAPSEDTIME">
					<xs:complexType>
						<xs:simpleContent>
							<xs:extension base="xs:time">
								<xs:attribute name="VALUE" type="xs:positiveInteger" use="required"/>
							</xs:extension>
						</xs:simpleContent>
					</xs:complexType>
				</xs:element>
				<xs:element name="REMAININGTIME">
					<xs:complexType>
						<xs:simpleContent>
							<xs:extension base="xs:time">
								<xs:attribute name="VALUE" type="xs:positiveInteger" use="required"/>
							</xs:extension>
						</xs:simpleContent>
					</xs:complexType>
				</xs:element>
				<xs:element name="RATE">
					<xs:complexType>
						<xs:simpleContent>
							<xs:extension base="xs:string">
								<xs:attribute name="VALUE" type="xs:positiveInteger" use="required"/>
							</xs:extension>
						</xs:simpleContent>
					</xs:complexType>
				</xs:element>
				<xs:element name="CURRENTRATE">
					<xs:complexType>
						<xs:simpleContent>
							<xs:extension base="xs:string">
								<xs:attribute name="VALUE" type="xs:positiveInteger" use="required"/>
							</xs:extension>
						</xs:simpleContent>
					</xs:complexType>
				</xs:element>
			</xs:sequence>
			<xs:attribute name="METER_ID" type="xs:hexBinary" use="required"/>
			<xs:attribute name="FILE" type="xs:string" use="required"/>
			<xs:attribute name="FINISHED" type="xs:boolean" use="required" default="0"/>
		</xs:complexType>
	</xs:element>
</xs:schema>
XSD-END
    $r->print($output);
    return Apache2::Const::OK;
}

1;