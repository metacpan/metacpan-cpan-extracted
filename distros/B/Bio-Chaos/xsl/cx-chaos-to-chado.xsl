<?xml version = "1.0"?>

<!-- AUTHOR: Chris Mungall  cjm at fruitfly dot org  -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output indent="yes" method="xml" />

  <xsl:key name="k-feature" match="feature" use="feature_id"/>
  <xsl:key name="k-floc-by-src" match="featureloc" use="srcfeature_id"/>

  <xsl:key 
    name="k-feature_relationship-by-obj" 
    match="//feature_relationship" 
    use="object_id"/>

  <xsl:key 
    name="k-feature_relationship-by-subj" 
    match="//feature_relationship" 
    use="subject_id"/>

  <!-- index of types -->
  <xsl:key name="k-ftype" match="//type[name(..)='feature']" use="."/>
  <xsl:key name="k-fptype" match="//type[name(..)='featureprop']" use="."/>
  <xsl:key name="k-frtype" match="//type[name(..)='feature_relationship']" use="."/>

  <xsl:key name="k-org" match="organismstr" use="."/>

  <xsl:template match="/chaos">

    <chado>

      <xsl:comment>
        <xsl:text>XORT macros - we can refer to these later</xsl:text>
      </xsl:comment>

      <!-- cv macros -->
      <cv op="force" id="sequence">
        <name>sequence</name>
      </cv>
      <cv op="force" id="feature_property">
        <name>feature_property</name>
      </cv>
      <cv op="force" id="relationship">
        <name>relationship</name>
      </cv>
      <cv op="force" id="synonym_type">
        <name>synonym_type</name>
      </cv>
      <cv op="force" id="cvterm_property_type">
        <name>cvterm_property_type</name>
      </cv>

      <!-- db macros -->
      <db op="force" id="OBO_REL">
        <name>OBO_REL</name>
      </db>
      <db op="force" id="SO">
        <name>SO</name>
      </db>
      <db op="force" id="internal">
        <name>internal</name>
      </db>

      <!-- comment_type macros -->
      <cvterm op="force" id="comment_type">
        <dbxref_id>
          <dbxref>
            <db_id>internal</db_id>
            <accession>cvterm_property_type</accession>
          </dbxref>
        </dbxref_id>
        <cv_id>cvterm_property_type</cv_id>
        <name>comment</name>
      </cvterm>

      <!-- organism macros -->
      <xsl:for-each select="//organismstr">
        <xsl:if test="generate-id(.) = generate-id(key('k-org', .)[1])">
          <organism>
            <xsl:attribute name="id">
              <xsl:text>organism__</xsl:text>
              <xsl:value-of select="."/>
            </xsl:attribute>
            <genus>
              <xsl:value-of select="substring-before(.,' ')"/>
            </genus>
            <species>
              <xsl:value-of select="substring-before(substring-after(.,' '),' ')"/>
            </species>
          </organism>
        </xsl:if>
      </xsl:for-each>

      <!-- SO macros, for feature types -->
      <xsl:for-each select="//feature">
        <xsl:if test="generate-id(type) = generate-id(key('k-ftype', type)[1])">
          <cvterm op="lookup">
            <xsl:attribute name="id">
              <xsl:text>sequence__</xsl:text>
              <xsl:value-of select="type"/>
            </xsl:attribute>
            <name>
              <xsl:value-of select="type"/>
            </name>
            <cv_id>
              <xsl:text>sequence</xsl:text>
            </cv_id>
          </cvterm>
        </xsl:if>
      </xsl:for-each>

      <!-- featureprop type macros -->
      <xsl:for-each select="//featureprop">
        <xsl:if test="generate-id(type) = generate-id(key('k-fptype', type)[1])">
          <cvterm op="lookup">
            <xsl:attribute name="id">
              <xsl:text>feature_property__</xsl:text>
              <xsl:value-of select="type"/>
            </xsl:attribute>
            <name>
              <xsl:value-of select="type"/>
            </name>
            <cv_id>
              <xsl:text>feature_property</xsl:text>
            </cv_id>
          </cvterm>
        </xsl:if>
      </xsl:for-each>

      <!-- feature_relationship type macros -->
      <xsl:for-each select="//feature_relationship">
        <xsl:if test="generate-id(type) = generate-id(key('k-frtype', type)[1])">
          <cvterm op="lookup">
            <xsl:attribute name="id">
              <xsl:text>relationship__</xsl:text>
              <xsl:value-of select="type"/>
            </xsl:attribute>
            <name>
              <xsl:value-of select="type"/>
            </name>
            <cv_id>
              <xsl:text>relationship</xsl:text>
            </cv_id>
          </cvterm>
        </xsl:if>
      </xsl:for-each>

      <xsl:comment>
        <xsl:text> features: top level of feature graph </xsl:text>
      </xsl:comment>
      <xsl:apply-templates select="feature[count(key('k-feature_relationship-by-subj',feature_id)) = 0]"/>
      <xsl:comment>
        <xsl:text> end of features </xsl:text>
      </xsl:comment>
    </chado>
  </xsl:template>

  <xsl:template match="featureloc">
    <featureloc>
      <srcfeature_id>
        <xsl:apply-templates mode="ref" select="key('k-feature',normalize-space(srcfeature_id))"/>
      </srcfeature_id>
      <strand>
        <xsl:value-of select="strand"/>
      </strand>
      <xsl:choose>
        <xsl:when test="strand >= 0">
          <fmin><xsl:value-of select="nbeg"/></fmin>
          <fmax><xsl:value-of select="nend"/></fmax>
        </xsl:when>
        <xsl:otherwise>
          <fmin><xsl:value-of select="nend"/></fmin>
          <fmax><xsl:value-of select="nbeg"/></fmax>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates mode="cp" select="rank"/>
      <xsl:apply-templates mode="cp" select="locgroup"/>
      <xsl:apply-templates mode="cp" select="residue_info"/>
    </featureloc>
  </xsl:template>

  <xsl:template match="featureprop">
    <featureprop>
      <xsl:apply-templates select="type">
        <xsl:with-param name="cv" value="feature_property">
          <xsl:text>feature_property</xsl:text>
        </xsl:with-param>
      </xsl:apply-templates>
      <value><xsl:value-of select="value"/></value>
    </featureprop>
  </xsl:template>

  <xsl:template match="feature_relationship">
    <feature_relationship>
      <xsl:apply-templates select="type">
        <xsl:with-param name="cv" value="relationship">
          <xsl:text>relationship</xsl:text>
        </xsl:with-param>
      </xsl:apply-templates>
      <subject_id>
        <xsl:apply-templates select="key('k-feature',subject_id)"/>
      </subject_id>
      <rank>
        <xsl:value-of select="rank"/>
      </rank>
    </feature_relationship>
  </xsl:template>

  <xsl:template match="feature">
    <feature>
      <xsl:apply-templates mode="cp" select="name"/>
      <xsl:choose>
        <xsl:when test="uniquename">
          <uniquename><xsl:value-of select="uniquename"/></uniquename>
        </xsl:when>
        <xsl:otherwise>
          <uniquename><xsl:value-of select="feature_id"/></uniquename>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="type">
        <xsl:with-param name="cv" value="sequence">
          <xsl:text>sequence</xsl:text>
        </xsl:with-param>
      </xsl:apply-templates>
      <xsl:apply-templates select="dbxrefstr"/>

      <xsl:call-template name="add-organism" select="."/>

      <xsl:apply-templates mode="cp" select="seqlen"/>
      <xsl:apply-templates mode="cp" select="residues"/>
      <xsl:apply-templates mode="cp" select="md5checksum"/>
      <is_analysis>
        <xsl:choose>
          <xsl:when test="is_analysis=1">
            <xsl:text>1</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>0</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </is_analysis>
      <xsl:apply-templates select="featureloc"/>
      <xsl:apply-templates select="featureprop"/>
      <xsl:comment>
        <xsl:text> nested feature_relationships </xsl:text>
      </xsl:comment>
      <xsl:apply-templates select="key('k-feature_relationship-by-obj',feature_id)"/>
    </feature>
  </xsl:template>

  <!-- only enough to uniquely identify feature -->
  <xsl:template mode="ref" match="feature">
    <feature>
      <xsl:choose>
        <xsl:when test="uniquename">
          <uniquename><xsl:value-of select="uniquename"/></uniquename>
        </xsl:when>
        <xsl:otherwise>
          <uniquename><xsl:value-of select="feature_id"/></uniquename>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="type">
        <xsl:with-param name="cv">
          <xsl:text>sequence</xsl:text>
        </xsl:with-param>
      </xsl:apply-templates>
      <xsl:call-template name="add-organism" select="."/>
    </feature>
  </xsl:template>

  <xsl:template name="add-organism">
    <xsl:apply-templates select="organismstr"/>
    <xsl:if test="not(organismstr)">
      <!-- feature implicitly has the organism of its parent in loc graph -->
      <xsl:apply-templates select="key('k-feature',featureloc[not(rank > 0)]/srcfeature_id)/organismstr"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="organismstr">
    <organism_id>
      <organism>
        <genus>
          <xsl:call-template name="first-word">
            <xsl:with-param name="str" select="."/>
          </xsl:call-template>
        </genus>
        <species>
          <xsl:call-template name="second-word">
            <xsl:with-param name="str" select="."/>
          </xsl:call-template>
        </species>
      </organism>
    </organism_id>
  </xsl:template>

  <xsl:template name="first-word">
    <xsl:param name="str"/>
    <xsl:choose>
      <xsl:when test="contains($str,' ')">
        <xsl:value-of select="substring-before($str,' ')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$str"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="second-word">
    <xsl:param name="str"/>
    <xsl:call-template name="first-word">
      <xsl:with-param name="str" select="substring-after($str,' ')"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="dbxrefstr">
    <dbxref_id>
      <dbxref>
        <db_id>
          <db>
            <name>
              <xsl:value-of select="substring-before(.,':')"/>
            </name>
          </db>
        </db_id>
        <accession>
          <xsl:value-of select="substring-after(.,':')"/>
        </accession>
      </dbxref>
    </dbxref_id>
  </xsl:template>

  <xsl:template match="type">
    <xsl:param name="cv"/>
    <type_id>
      <xsl:value-of select="$cv"/>
      <xsl:text>__</xsl:text>
      <xsl:value-of select="."/>
    </type_id>
  </xsl:template>
  
  <xsl:template match="text()|@*">
  </xsl:template>

  <xsl:template mode="cp" match="text()|@*">
    <xsl:copy-of select=".."/>
  </xsl:template>

  <xsl:template mode="escape" match="text()">
    <xsl:value-of select="translate(.,' ','+')"/>
  </xsl:template>

</xsl:stylesheet>
