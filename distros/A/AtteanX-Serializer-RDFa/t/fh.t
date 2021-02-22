#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Modern qw(cmp_deeply set);

BEGIN {
  use_ok('Attean') or BAIL_OUT "Attean required for tests";
  use_ok('AtteanX::Serializer::RDFa');
  use_ok('RDF::RDFa::Generator');
}

use Attean::RDF qw(iri);
use URI::NamespaceMap;

my $ns = URI::NamespaceMap->new( { ex => iri('http://example.org/') });
$ns->guess_and_add('foaf');

my $store = Attean->get_store('Memory')->new();
my $parser = Attean->get_parser('Turtle')->new(base=>'http://example.org/');

my $iter = $parser->parse_iter_from_bytes('<http://example.org/foo> a <http://example.org/Bar> ; <http://example.org/title> "Dahut"@fr ; <http://example.org/something> [ <http://example.org/else> "Foo" ; <http://example.org/pi> 3.14 ] .')->materialize;


ok(my $ser = Attean->get_serializer('RDFa')->new(base => iri('http://example.org/'),
																 namespaces => $ns)
	, 'Assignment OK');

cmp_deeply($ser->media_types, set(qw(application/xhtml+xml text/html)) );
cmp_deeply($ser->file_extensions, set(qw(html xhtml)) );

my $string = tests($ser);
like($string, qr|<meta name="generator" value="RDF::RDFa::Generator::HTML::Head"/>|, 'Head generator is correct');
like($string, qr|xmlns:foaf="http://xmlns.com/foaf/0.1/"|, 'FOAF is in there');
unlike($string, qr|xmlns:hydra="http://www.w3.org/ns/hydra/core#"|, 'But not hydra');
like($string, qr|resource="http://example.org/Bar"|, 'Object present');
like($string, qr|property="ex:title" content="Dahut"|, 'Literals OK');

sub tests {
  my $ser = shift;
  my $string = '';
  open my ($fh), '>', \$string;
  $ser->serialize_iter_to_io($fh, $iter);
  like($string, qr|about="http://example.org/foo"|, 'Subject URI present');
  like($string, qr|rel="rdf:type"|, 'Type predicate present');
  like($string, qr|property="ex:pi"|, 'pi predicate present');
  like($string, qr|3\.14|, 'pi decimal present');
  like($string, qr|datatype="xsd:decimal"|, 'pi decimal datatype present');
  return $string;
}
done_testing();
