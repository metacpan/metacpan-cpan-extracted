#!/usr/bin/env perl
# test the rdf examples, but fake the RDF.
use warnings;
use strict;

use lib 'lib';
#use lib 'XML-Compile-1.35-raw/lib';
use Test::More;

use Data::DublinCore       ();
use Data::DublinCore::Util qw/NS_DC_TERMS NS_DC_ELEMS11/;
use XML::Compile::Util     qw/SCHEMA2001 pack_type/;
use File::Basename         qw/basename/;

use Data::Dumper;
#use Log::Report mode => 'DEBUG';

$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys  = 1;

my @examples = map { glob $_ } qw(examples/rdf*);
my $rdf_ns   = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
my $rdf_top  = pack_type $rdf_ns, 'RDF';

my $dcns     = NS_DC_ELEMS11;
my $dcterms  = NS_DC_TERMS;
my $schemans = SCHEMA2001;

@examples
   or plan skip_all => 'cannot find examples';

plan tests => 8;

my $dc = Data::DublinCore->new;
isa_ok($dc, 'Data::DublinCore');
is($dc->version, '20080211');

# the examples use RDF, but I have not implemented RDF... so fake
# things which are useful.
$dc->prefixes(rdf => $rdf_ns);
$dc->addKeyRewrite('PREFIXED(rdf)');
$dc->importDefinitions( <<_FAKE_RDF );
<schema
   targetNamespace="$rdf_ns"
   xmlns="$schemans"
   xmlns:rdf="$rdf_ns"
   xmlns:dc="$dcns"
   xmlns:dcterms="$dcterms"
   elementFormDefault="qualified"
   attributeFormDefault="qualified">

<element name="RDF">
  <complexType>
    <sequence>
      <element name="Description" type="rdf:Description"
         minOccurs="0" maxOccurs="unbounded"/>
    </sequence>
  </complexType>
</element>

<complexType name="Description">
  <sequence>
    <element ref="dc:any" minOccurs="0" maxOccurs="unbounded"/>
  </sequence>
  <attribute ref="rdf:about" use="optional"/>
</complexType>

<attribute name="about" type="anyURI"/>
<attribute name="resource" type="anyURI"/>

</schema>
_FAKE_RDF

my %expected =
 ( 'rdf1.xml' => { rdf_Description =>
     [ { rdf_about => 'http://media.example.com/audio/guide.ra', dc_any => [
        { dc_creator => 'Rose Bush' },
        { dc_title => 'A Guide to Growing Roses' },
        { dc_description => 'Describes process for planting and nurturing different kinds of rose bushes.' },
        { dc_date => '2001-01-20' } ] } ] }

 , 'rdf2.xml' => { rdf_Description => [
        { rdf_about => 'http://example.org/'
        , dc_any => [ { dc_source =>
            {'rdf:resource' => 'http://example.org/elsewhere/'} } ] },
    { dc_any => [
        { dc_title => 'Internet Ethics' },
        { dc_creator => 'Duncan Langford' },
        { dc_format => 'Book' },
        { dc_identifier => 'ISBN 0333776267' } ] },
    { dc_any => [
        { dc_title => 'The Mona Lisa' },
        { dc_description => 'A painting by ...' } ] } ] }

 , 'rdf3.xml' => { rdf_Description =>
     [ { rdf_about => 'http://www.ilrt.bristol.ac.uk/people/cmdjb/', dc_any => [
        { dc_title => 'Dave Beckett\'s Home Page' },
        { dc_creator => 'Dave Beckett' },
        { dc_publisher => 'ILRT, University of Bristol' },
        { dc_date => '2002-07-31' } ] } ] }

 , 'rdf4.xml' => {
  rdf_Description => [ { rdf_about => 'http://dublincore.org/', dc_any =>
      [ { dc_title => 'Dublin Core Metadata Initiative - Home Page' },
        { dc_description => 'The Dublin Core Metadata Initiative Web site.' },
        { dc_date => '2001-01-16' },
        { dc_format => 'text/html' },
        { dc_language => 'en' },
        { dc_contributor => 'The Dublin Core Metadata Initiative' },
        { dc_title =>
            { _          => "L'Initiative de m\x{e9}tadonn\x{e9}es du Dublin Core"
            , 'xml:lang' => 'fr'
            } },
        { dc_title =>
            { _          => 'der Dublin-Core Metadata-Diskussionen'
            , 'xml:lang' => 'de'
            } }
      ] } ] }

 , 'rdf5.xml' => {
     rdf_Description => [ { dc_any =>
      [ { dc_creator => 'a' },
        { dc_contributor => 'b' },
        { dc_publisher => 'c' },
        { dc_subject => 'd' },
        { dc_description => 'e' },
        { dc_identifier => 'f' },
        { dc_relation => 'g' },
        { dc_source => 'h' },
        { dc_rights => 'i' },
        { dc_format => 'j' },
        { dc_type => 'k' },
        { dc_title => 'l' },
        { dc_date => 'm' },
        { dc_coverage => 'n' },
        { dc_language => 'o' }
      ] } ] }

 , 'rdf6.xml' => {
      rdf_Description => [ {
        dc_any => [ {
          dc_subject => {
            'dcterms:MESH' => {
              'rdf:value' => 'D08.586.682.075.400',
              'rdfs:label' => 'Formate Dehydrogenase'
            } }
        } ]
    } ] }
 );

foreach my $example (@examples)
{   my $data = $dc->reader($rdf_top)->($example);

    my $base = basename $example;
    is_deeply($data, $expected{$base}, $base);
#warn "READ: ", Dumper $data;
}
