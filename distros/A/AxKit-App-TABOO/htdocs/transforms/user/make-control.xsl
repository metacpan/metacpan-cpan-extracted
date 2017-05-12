<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ct="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Control"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:userinc="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Include"
  xmlns="http://www.w3.org/1999/xhtml">
  <xsl:output method="xml" version="1.0" encoding="utf-8"
    media-type="text/xml" indent="yes"/>  


  <xsl:template match="ct:control">
    <xsl:choose>
      <xsl:when test="@name='authlevel'">
	<xsl:if test="boolean(ct:value/user:level)">
	  <!-- If the user can't set the authlevel, we shouldn't
	  display the control -->
	  <ct:control>
	    <xsl:copy-of select="ct:title|ct:descr|@*"/>
	    <ct:value>
	      <xsl:copy-of select="ct:value/user:level"/>
	    </ct:value>
	  </ct:control>
	</xsl:if>
      </xsl:when>
      <xsl:otherwise>
	<ct:control>
	  <xsl:copy-of select="ct:title|ct:descr|@*"/>
	  <ct:value>
	    <xsl:apply-templates select="ct:value/userinc:*"/>
	    <xsl:copy-of select="ct:value/node()"/>
	  </ct:value>
	</ct:control>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="userinc:name">
    <xsl:value-of select="//user:name"/>
  </xsl:template>
  <xsl:template match="userinc:email">
    <xsl:value-of select="//user:email"/>
  </xsl:template>
  
  <xsl:template match="userinc:uri">
    <xsl:value-of select="//user:uri"/>
  </xsl:template>

  <xsl:template match="userinc:bio">
    <xsl:value-of select="//user:bio"/>
  </xsl:template>


  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>


