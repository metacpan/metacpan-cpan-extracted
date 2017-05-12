<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:cust="http://www.kjetil.kjernsmo.net/software/TABOO/NS/CustomGrammar"
  xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output"
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
  that I couldn't find a way in which I could first construct a Story
  object and then load it, and then have those elements use the
  allready loaded data. So, the alternative was to load the same data
  several times, which felt even worse. Besides, there is a special
  case I would have to deal with too. Perhaps I could do it if I let
  go of not having Perl code in my XSP, but... Suggestion are welcome. -->

  <xsl:param name="title"/>

  <xsl:template match="val:insert[@name='title']">
    <xsl:if test="$title = ''">
      <xsl:value-of select="/cust:submit/story:story-loaded/story:story/story:title"/>  
    </xsl:if>
    <xsl:if test="not($title = '')">
      <xsl:value-of select="$title"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="minicontent"/>

  <xsl:template match="val:insert[@name='minicontent']">
    <xsl:if test="$minicontent = ''">
      <xsl:copy-of select="/cust:submit/story:story-loaded/story:story/story:minicontent"/>  
    </xsl:if>
    <xsl:if test="not($minicontent = '')">
      <xsl:value-of select="$minicontent"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="content"/>

  <xsl:template match="val:insert[@name='content']">
    <xsl:if test="$content = ''">
      <xsl:apply-templates select="/cust:submit/story:story-loaded/story:story/story:content"/>  
    </xsl:if>
    <xsl:if test="not($content = '')">
      <xsl:value-of select="$content"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="image"/>

  <xsl:template match="val:insert[@name='image']">
    <xsl:if test="$image = ''">
      <xsl:value-of select="/cust:submit/story:story-loaded/story:story/story:image"/>  
    </xsl:if>
    <xsl:if test="not($image = '')">
      <xsl:value-of select="$image"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="linktext"/>

  <xsl:template match="val:insert[@name='linktext']">
    <xsl:if test="$linktext = ''">
      <xsl:value-of select="/cust:submit/story:story-loaded/story:story/story:linktext"/>  
    </xsl:if>
    <xsl:if test="not($linktext = '')">
      <xsl:value-of select="$linktext"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="primcat"/>

  <xsl:template match="val:insert[@name='primcat']">
    <xsl:if test="$primcat = ''">
      <xsl:value-of select="/cust:submit/story:story-loaded/story:story/story:primcat"/>  
    </xsl:if>
    <xsl:if test="not($primcat = '')">
      <xsl:value-of select="$primcat"/>  
    </xsl:if>
  </xsl:template>


  <xsl:param name="sectionid"/>

  <xsl:template match="val:insert[@name='sectionid']">
    <xsl:if test="$sectionid = ''">
      <xsl:value-of select="/cust:submit/story:story-loaded/story:story/story:sectionid"/>  
    </xsl:if>
    <xsl:if test="not($sectionid = '')">
      <xsl:value-of select="$sectionid"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="editorok"/>

  <xsl:template match="val:insert[@name='editorok']">
    <xsl:if test="$editorok = ''">
      <xsl:value-of select="/cust:submit/story:story-loaded/story:story/story:editorok"/>  
    </xsl:if>
    <xsl:if test="not($editorok = '')">
      <xsl:value-of select="$editorok"/>  
    </xsl:if>    
  </xsl:template>

  <xsl:param name="submitterid"/>

  <xsl:template match="val:insert[@name='submitterid']">
    <xsl:if test="$submitterid = ''">
      <xsl:value-of select="/cust:submit/story:story-loaded/story:story/user:submitter/user:username"/>  
    </xsl:if>
    <xsl:if test="not($submitterid = '')">
      <xsl:value-of select="$submitterid"/>  
    </xsl:if>    
  </xsl:template>


  <xsl:param name="storyname"/>

  <xsl:template match="val:insert[@name='storyname']">
    <xsl:if test="$storyname = ''">
      <xsl:value-of select="/cust:submit/story:story-loaded/story:story/story:storyname"/>  
    </xsl:if>
    <xsl:if test="not($storyname = '')">
      <xsl:value-of select="$storyname"/>  
    </xsl:if>    
  </xsl:template>


  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

