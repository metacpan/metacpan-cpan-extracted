use strict;
use warnings;
use Test::More;
use Catmandu::XML::Transformer;
use XML::LibXML;

my $transformer = Catmandu::XML::Transformer->new(
    stylesheet => 't/transform1.xsl'
);

is_deeply $transformer->stylesheet, ['t/transform1.xsl'], 'stylesheet';
is $transformer->output_format, undef, 'output_format';

is $transformer->transform( '<doc attr="bar"/>' ),
   "<?xml version=\"1.0\"?>\n<foo>bar</foo>\n", 'xml_string';

my $xml_dom = XML::LibXML->load_xml(string => '<doc attr="bar"/>');
my $result = $transformer->transform($xml_dom); 
isa_ok $result, 'XML::LibXML::Document';
is $result, "<?xml version=\"1.0\"?>\n<foo>bar</foo>\n", 'xml_dom';

$xml_dom = XML::LibXML->load_xml('string','<doc attr="bar"/>')->documentElement;
isa_ok $transformer->transform($xml_dom), 'XML::LibXML::Document';

is_deeply $transformer->transform( [ doc => { attr => "bar" }, [ ] ] ),
   [ 'foo', {}, [ 'bar' ] ], 'xml_struct';

is_deeply $transformer->transform( { doc => 0 } ),
   { foo => {} }, 'xml_simple';

$transformer = Catmandu::XML::Transformer->new( 
    stylesheet => 't/transform2.xsl' );
is $transformer->output_format, 'string', 'output method=text';

$transformer = Catmandu::XML::Transformer->new(
    stylesheet => 't/transform1.xsl',
    output_format => 'DOM',
);
is $transformer->output_format, 'dom', 'normalize output_format';

done_testing;
