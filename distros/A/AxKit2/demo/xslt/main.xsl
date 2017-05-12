<?xml version="1.0"?>
<xsl:stylesheet
	       version="1.0"
   	       xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:include href="pod.xsl"/>

<xsl:output method="html"/>

<xsl:template match="/">
  <html>
    <head>
      <title>AxKit Docs :: <xsl:value-of select="/xspwiki/page"/></title>
      <link rel="stylesheet" href="/stylesheets/default.css"/>
    </head>
	
    <body>
      <div class="topbanner">
        AxKit Docs
      </div>
      <div class="main-content">
        <xsl:apply-templates/>
      </div>
    </body>
  </html>
</xsl:template>

</xsl:stylesheet>
