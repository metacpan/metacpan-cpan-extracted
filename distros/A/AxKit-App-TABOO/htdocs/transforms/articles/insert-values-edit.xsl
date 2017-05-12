<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:cust="http://www.kjetil.kjernsmo.net/software/TABOO/NS/CustomGrammar"
  xmlns:art="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article/Output"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:val="http://www.kjetil.kjernsmo.net/software/TABOO/NS/FormValues"
  xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <xsl:output version="1.0" encoding="utf-8"
    media-type="text/xml" indent="yes"/>  

  <!-- There's a discussion of the approach I take in this file to the
  problem of inserting the values in the case where we want to edit
  the contents that has allready been saved in
  http://maclux-rz.uibk.ac.at/maillists/axkit-users/msg07073.shtml 
  I ended up with the cut'n'paste approach. It doesn't feel good,
  though, therefore this discussion. The alternative would be to
  replace the val:insert elements in the submit.xsp with a taglib
  element that could choose it. The problem with this approach was
  that I couldn't find a way in which I could first construct a Article
  object and then load it, and then have those elements use the
  allready loaded data. So, the alternative was to load the same data
  several times, which felt even worse. Besides, there is a special
  case I would have to deal with too. Perhaps I could do it if I let
  go of not having Perl code in my XSP, but... Suggestion are welcome. -->

  <xsl:param name="title"/>

  <xsl:template match="val:insert[@name='title']">
    <xsl:if test="$title = ''">
      <xsl:value-of select="/cust:submit/art:article-loaded/art:article/art:title"/>  
    </xsl:if>
    <xsl:if test="not($title = '')">
      <xsl:value-of select="$title"/>  
    </xsl:if>    
  </xsl:template>


  <xsl:param name="description"/>

  <xsl:template match="val:insert[@name='description']">
    <xsl:if test="$description = ''">
      <xsl:value-of select="/cust:submit/art:article-loaded/art:article/art:description"/>  
    </xsl:if>
    <xsl:if test="not($description = '')">
      <xsl:value-of select="$description"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="primcat"/>

  <xsl:template match="val:insert[@name='primcat']">
    <xsl:if test="$primcat = ''">
      <xsl:value-of select="/cust:submit/art:article-loaded/art:article/art:primcat"/>  
    </xsl:if>
    <xsl:if test="not($primcat = '')">
      <xsl:value-of select="$primcat"/>  
    </xsl:if>
  </xsl:template>

  <xsl:param name="code"/>

  <xsl:template match="val:insert[@name='code']">
    <xsl:if test="$code = ''">
      <xsl:value-of select="/cust:submit/art:article-loaded/art:article/art:code"/>  
    </xsl:if>
    <xsl:if test="not($code = '')">
      <xsl:value-of select="$code"/>  
    </xsl:if>
  </xsl:template>


  <xsl:param name="editorok"/>

  <xsl:template match="val:insert[@name='editorok']">
    <xsl:if test="$editorok = ''">
      <xsl:value-of select="/cust:submit/art:article-loaded/art:article/art:editorok"/>  
    </xsl:if>
    <xsl:if test="not($editorok = '')">
      <xsl:value-of select="$editorok"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="authorid"/>

  <xsl:template match="val:insert[@name='authorid']">
    <xsl:if test="$authorid = ''">
      <xsl:value-of select="/cust:submit/art:article-loaded/art:article/user:author/user:username"/>  
    </xsl:if>
    <xsl:if test="not($authorid = '')">
      <xsl:value-of select="$authorid"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="upfile"/>

  <xsl:template match="val:insert[@name='upfile']">
    <xsl:if test="$upfile = ''">
      <xsl:value-of select="/cust:submit/art:article-loaded/art:article/art:upfile"/>  
    </xsl:if>
    <xsl:if test="not($upfile = '')">
      <xsl:value-of select="$upfile"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="filename"/>

  <xsl:template match="val:insert[@name='filename']">
    <xsl:if test="$filename = ''">
      <xsl:value-of select="/cust:submit/art:article-loaded/art:article/art:filename"/>  
    </xsl:if>
    <xsl:if test="not($filename = '')">
      <xsl:value-of select="$filename"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="text"/>

  <xsl:template match="val:insert[@name='text']">
    <xsl:value-of select="$text"/>  
  </xsl:template>


  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

