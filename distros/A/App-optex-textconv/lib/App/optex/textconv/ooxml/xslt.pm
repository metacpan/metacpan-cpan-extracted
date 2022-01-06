package App::optex::textconv::ooxml::xslt;

our $VERSION = '1.01';

use v5.14;
use warnings;
use Carp;
use utf8;
use Encode;
use Data::Dumper;

use App::optex::textconv::Converter 'import';

our @EXPORT_OK = qw(to_text get_list);

our @CONVERTER = (
    [ qr/\.doc[xm]$/ => \&to_text ],
    [ qr/\.ppt[xm]$/ => \&to_text ],
#   [ qr/\.xls[xm]$/ => \&to_text ],
    );

my %styles = (

##
## Extract text from docx data.
##
## s/w:tabs/  /g;
## for //w:p {
##     next unless .//w:t
##     for .//w:r {
##         for w:t {
##             s/w:tab/  /g;
##             print value;
##         }
##     }
##     print "\n\n";
## }
##
docx => q{
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <xsl:output method="text" />
  <xsl:template match="/">
    <xsl:apply-templates select="//w:p" />
  </xsl:template>
  <xsl:template match="w:p">
    <xsl:if test=".//w:t">
      <xsl:apply-templates/>
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:if>
  </xsl:template>
  <xsl:template match="w:tabs">
    <xsl:text>  </xsl:text>
  </xsl:template>
  <xsl:template match="w:r">
    <xsl:for-each select="w:t">
      <xsl:value-of select="." />
    </xsl:for-each>
    <xsl:for-each select="w:tab">
      <xsl:text>  </xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
},

##
## Extract text from pptx data.
##
## for //a:p {
##     next unless .//a:t
##     for a:r {
##         for a:t {
##             print value;
##         }
##     }
##     print "\n";
## }
##
pptx => q{
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <xsl:output method="text" />
  <xsl:template match="/">
    <xsl:apply-templates select="//a:p" />
  </xsl:template>
  <xsl:template match="a:p">
    <xsl:if test=".//a:t">
      <xsl:apply-templates/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>
  <xsl:template match="a:r">
    <xsl:for-each select="a:t">
      <xsl:value-of select="." />
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
},

##
## This code just extract all text with no space.
##
xlsx => q{
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <xsl:output method="text" />
</xsl:stylesheet>
},

##
## This an experimental code for docx to extract table/picture information.
##
descriptive_docx => q{
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <xsl:output method="text" />
  <xsl:template match="/">
    <xsl:apply-templates select="//w:body | //w:footnote" />
  </xsl:template>
  <xsl:template match="w:tbl">
    <xsl:text>[ TABLE START ]&#10;&#10;</xsl:text>
    <xsl:apply-templates select=".//w:p" />
    <xsl:text>[ TABLE END ]&#10;&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="w:p">
    <xsl:if test=".//w:t">
      <xsl:apply-templates/>
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:if>
  </xsl:template>
  <xsl:template match="w:tabs">
    <xsl:text>  </xsl:text>
  </xsl:template>
  <xsl:template match="w:r">
    <xsl:for-each select="w:t">
      <xsl:value-of select="." />
    </xsl:for-each>
    <xsl:for-each select="w:tab">
      <xsl:text>  </xsl:text>
    </xsl:for-each>
    <xsl:for-each select="w:pict">
      <xsl:text>[ PICTURE START ]&#10;&#10;</xsl:text>
      <xsl:apply-templates select=".//w:p" />
      <xsl:text>[ PICTURE END ]&#10;&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
},

##
## This is an original code included in Text::Distill module.
##
Text_Distill_docx => q{
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <xsl:output method="text" />
  <xsl:template match="/">
    <xsl:apply-templates select="//w:body" />
  </xsl:template>
  <xsl:template match="w:body">
    <xsl:apply-templates />
  </xsl:template>
  <xsl:template match="w:p">
    <xsl:if test="w:pPr/w:spacing/@w:after=0"><xsl:text>&#10;&#10;</xsl:text></xsl:if>
    <xsl:apply-templates/><xsl:if test="position()!=last()"><xsl:text>&#10;&#10;</xsl:text></xsl:if>
  </xsl:template>
  <xsl:template match="w:r">
    <xsl:for-each select="w:t">
      <xsl:value-of select="." />
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
},
    );

for (keys %styles) {
    if (/^(...)x/) {
	$styles{$1."m"} //= $styles{$_};
    }
}

use XML::LibXML;
use XML::LibXSLT;

my %LibXMLParserOptions = (
    'no_network'      => 1,
    'expand_entities' => 0,
    'load_ext_dtd'    => 0,
    );

use Archive::Zip 1.37 qw( :ERROR_CODES :CONSTANTS );

sub xml2text {
    local $_ = shift;
    my $type = shift;
    my $xml_re = qr/(?=<\?xml\b[^>]*\?>\s*)/;
    return $_ unless /$xml_re/;

    my @xml  = grep { length } split /$xml_re/;
    my @text = map  { _xml2text($_, $type) } @xml;
    join "\n", @text;
}

sub _xml2text {
    my $xml_document = shift;
    my $type = shift;

    my $xml  = XML::LibXML->new(%LibXMLParserOptions);
    my $xslt = XML::LibXSLT->new();

    my $document = eval { $xml->parse_string($xml_document) };
    if ($@) {
	confess "[libxml2 error ". $@->code() ."] ". $@->message();
    }

    my $style_doc   = $xml->load_xml(string => $styles{$type});
    my $style_sheet = $xslt->parse_stylesheet($style_doc);
    my $transform = $style_sheet->transform($document);
    my $result = $style_sheet->output_string($transform);

    $result;
}

sub to_text {
    my $file = shift;
    my $type = ($file =~ /\.((?:doc|xls|ppt)[xm])$/)[0] or return;
    my $zip = Archive::Zip->new($file) or die;
    my @contents;
    for my $entry (get_list($zip, $type)) {
	my $member = $zip->memberNamed($entry) or next;
	my $xml = $member->contents or next;
	my $text = xml2text $xml, $type or next;
	$file = encode 'utf8', $file if utf8::is_utf8($file);
	push @contents, "[ \"$file\" $entry ]\n\n$text";
    }
    join "\n", @contents;
}

sub get_list {
    my($zip, $type) = @_;
    if    ($type =~ /^doc[xm]$/) {
	map { "word/$_.xml" } qw(document endnotes footnotes);
    }
    elsif ($type =~ /^xls[xm]$/) {
	map { "xl/$_.xml" } qw(sharedStrings);
    }
    elsif ($type =~ /^ppt[xm]$/) {
	map  { $_->[0] }
	sort { $a->[1] <=> $b->[1] }
	map  { m{(ppt/slides/slide(\d+)\.xml)$} ? [ $1, $2 ] : () }
	$zip->memberNames;
    }
}

1;
