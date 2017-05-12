<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:template match="/">
<html>
  <body>
    <h1>Edit Page</h1>
    <form method="get">
      <textarea name="text" rows="15" cols="80"><xsl:copy-of select="/"/></textarea>
      <input type="hidden" name="edit" value="1"/>
      <input type="submit" value="save"/>
    </form>
  </body>
</html>
</xsl:template>

</xsl:stylesheet>
