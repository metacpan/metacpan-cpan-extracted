#!/usr/bin/env perl
use Catmandu::Sane;
use open qw(:std :utf8);
use XML::LibXML;
use XML::LibXML::XPathContext;
use Data::Dumper;

local($/) = undef;
my $str = <DATA>;
my $xml = XML::LibXML->load_xml(string => $str);
my $xpath = XML::LibXML::XPathContext->new($xml);

my($node) = $xpath->find("/ill-get-doc/*[local-name() = 'record']")->get_nodelist();
say "node: $node";

__DATA__
<?xml version = "1.0" encoding = "UTF-8"?>
<ill-get-doc>
<record xmlns="http://www.loc.gov/MARC21/slim/"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.loc.gov/MARC21/slim
http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
<leader>00000cam^^2200217u^^4500</leader>
<controlfield tag="001">001317121</controlfield>
<controlfield tag="005">20130221093138.0</controlfield>
<controlfield tag="008">831220q18211833gw^||||||||||^0^^^|^mul^^</controlfield>
<datafield tag="010" ind1=" " ind2=" ">
<subfield code="a">67071652</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
<subfield code="9">(DLC) 67071652</subfield>
</datafield>
<datafield tag="040" ind1=" " ind2=" ">
<subfield code="a">DLC</subfield>
<subfield code="c">CarP</subfield>
<subfield code="d">DLC</subfield>
</datafield>
<datafield tag="041" ind1="0" ind2=" ">
<subfield code="a">latgrc</subfield>
</datafield>
<datafield tag="050" ind1="0" ind2="0">
<subfield code="a">R126.A1</subfield>
<subfield code="b">K82</subfield>
</datafield>
<datafield tag="100" ind1="1" ind2=" ">
<subfield code="a">Galenus, Claudius,</subfield>
<subfield code="d">ca. 130-ca. 200</subfield>
</datafield>
<datafield tag="245" ind1="1" ind2="0">
<subfield code="a">Claudii Galeni Opera omnia /</subfield>
<subfield code="c">Editionem curavit Carolus Gottlob. Kühn.</subfield>
</datafield>
<datafield tag="246" ind1="2" ind2=" ">
<subfield code="a">Κλαυδίου Γαληνοῦ ἅπαντα</subfield>
</datafield>
<datafield tag="246" ind1="2" ind2=" ">
<subfield code="a">[Klaudiou Galinou Apanta]</subfield>
</datafield>
<datafield tag="260" ind1=" " ind2=" ">
<subfield code="a">Lipsiae :</subfield>
<subfield code="b">prostat in officina libraria Car. Cnoblochii,</subfield>
<subfield code="c">1821-1833.</subfield>
</datafield>
<datafield tag="300" ind1=" " ind2=" ">
<subfield code="a">20 v. ; 8°.</subfield>
</datafield>
<datafield tag="490" ind1="0" ind2=" ">
<subfield code="a">Medicorum graecorum opera quae exstant ;</subfield>
<subfield code="v">1-20</subfield>
</datafield>
<datafield tag="561" ind1=" " ind2=" ">
<subfield code="a">Herkomst ACC.6673: Ex libris J. Roulez:</subfield>
</datafield>
<datafield tag="546" ind1=" " ind2=" ">
<subfield code="a">Tekst in het Grieks en het Latijn</subfield>
</datafield>
<datafield tag="650" ind1=" " ind2="0">
<subfield code="a">Medicine</subfield>
<subfield code="x">Early works to 1800</subfield>
</datafield>
<datafield tag="650" ind1=" " ind2="0">
<subfield code="a">Medicine, Greek and Roman</subfield>
<subfield code="v">Early works to 1800</subfield>
</datafield>
<datafield tag="700" ind1="1" ind2=" ">
<subfield code="a">Kühn, Karl Gottlob,</subfield>
<subfield code="d">1754-1840</subfield>
</datafield>
<datafield tag="920" ind1=" " ind2=" ">
<subfield code="a">book</subfield>
</datafield>
</record>
<session-id>V1CN2GYVR9KRY87PKQL1S1C123Q2R4S4KJS8SDH5TA23C8B3AD</session-id>
</ill-get-doc>
