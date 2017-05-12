<?xml version="1.0"?>
<xsl:stylesheet
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     version="1.0">


<xsl:output method="html" />
<!-- URI params -->
<xsl:param name="request.uri.path">--</xsl:param>
<xsl:param name="request.uri.scheme">--</xsl:param>
<xsl:param name="request.uri.port">--</xsl:param>
<xsl:param name="request.uri.rpath">--</xsl:param>
<xsl:param name="request.uri.query">--</xsl:param>
<xsl:param name="request.uri.user">--</xsl:param>
<xsl:param name="request.uri.password">--</xsl:param>
<xsl:param name="request.uri.fragment">--</xsl:param>
<!-- end URI params -->

<!-- HTTPHeader params -->
<xsl:param name="request.headers.accept">--</xsl:param>
<xsl:param name="request.headers.content-type">--</xsl:param>
<xsl:param name="request.headers.accept-charset">--</xsl:param>
<xsl:param name="request.headers.accept-encoding">--</xsl:param>
<xsl:param name="request.headers.accept-language">--</xsl:param>
<xsl:param name="request.headers.connection">--</xsl:param>
<xsl:param name="request.headers.host">--</xsl:param>
<xsl:param name="request.headers.pragma">--</xsl:param>
<xsl:param name="request.headers.user-agent">--</xsl:param>
<xsl:param name="request.headers.from">--</xsl:param>
<xsl:param name="request.headers.referer">--</xsl:param>
<!-- end HTTPHeader params -->

<!-- "common" params -->
<xsl:param name="request.method">--</xsl:param>
<xsl:param name="request.uri">--</xsl:param>
<xsl:param name="request.filename">--</xsl:param>
<xsl:param name="request.path_info">--</xsl:param>
<!-- end "common" params -->

<xsl:template match="/">
  <html>
    <body>

    <table border="1" cellpadding="2" cellspacing="3" bgcolor="eeeeee">
      <tr><th colspan="2">Common Params</th></tr>
      <tr>
       <td>request.uri</td><td><xsl:value-of select="$request.uri"/></td>
      </tr>
      <tr>
       <td>request.method</td><td><xsl:value-of select="$request.method"/></td>
      </tr>
      <tr>
       <td>request.filename</td><td><xsl:value-of select="$request.path_info"/></td>
      </tr>
      <tr>
       <td>request.path_info</td><td><xsl:value-of select="$request.path_info"/></td>
      </tr>
    </table>
    
    <br />

    <table border="1" cellpadding="2" cellspacing="3" bgcolor="eeeeee">
      <tr><th colspan="2">HTTP Headers</th></tr>
      <tr>
       <td>request.headers.accept</td><td><xsl:value-of select="$request.headers.accept"/></td>
      </tr>
      <tr>
       <td>request.headers.accept-charset</td><td><xsl:value-of select="$request.headers.accept-charset"/></td>
      </tr>
      <tr>
       <td>request.headers.accept-encoding</td><td><xsl:value-of select="$request.headers.accept-encoding"/></td>
      </tr>
      <tr>
       <td>request.headers.accept-language</td><td><xsl:value-of select="$request.headers.accept-language"/></td>
      </tr>
      <tr>
       <td>request.headers.connection</td><td><xsl:value-of select="$request.headers.connection"/></td>
      </tr>
      <tr>
       <td>request.headers.host</td><td><xsl:value-of select="$request.headers.host"/></td>
      </tr>
      <tr>
       <td>request.headers.pragma</td><td><xsl:value-of select="$request.headers.pragma"/></td>
      </tr>
      <tr>
       <td>request.headers.content-type</td><td><xsl:value-of select="$request.headers.content-type"/></td>
      </tr>
      <tr>
       <td>request.headers.from</td><td><xsl:value-of select="$request.headers.from"/></td>
      </tr>
      <tr>
       <td>request.headers.referer</td><td><xsl:value-of select="$request.headers.referer"/></td>
      </tr>
      <tr>
       <td>request.headers.user-agent</td><td><xsl:value-of select="$request.headers.user-agent"/></td>
      </tr>
    </table>
    
    <br />

    <table border="1" cellpadding="2" cellspacing="3" bgcolor="eeeeee">
      <tr><th colspan="2">Verbose URI params</th></tr>
      <tr>
       <td>request.uri.path</td><td><xsl:value-of select="$request.uri.path"/></td>
      </tr>
      <tr>
       <td>request.uri.scheme</td><td><xsl:value-of select="$request.uri.scheme"/></td>
      </tr>
      <tr>
       <td>request.uri.port</td><td><xsl:value-of select="$request.uri.port"/></td>
      </tr>
      <tr>
       <td>request.uri.rpath</td><td><xsl:value-of select="$request.uri.rpath"/></td>
      </tr>
      <tr>
       <td>request.uri.query</td><td><xsl:value-of select="$request.uri.query"/></td>
      </tr>
      <tr>
       <td>request.uri.user</td><td><xsl:value-of select="$request.uri.user"/></td>
      </tr>
      <tr>
       <td>request.uri.password</td><td><xsl:value-of select="$request.uri.password"/></td>
      </tr>
      <tr>
       <td>request.uri.fragment</td><td><xsl:value-of select="$request.uri.fragment"/></td>
      </tr>
    </table>
    </body>
  </html>
</xsl:template>

</xsl:stylesheet>
