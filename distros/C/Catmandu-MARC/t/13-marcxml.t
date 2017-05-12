use strict;
use warnings;

use Catmandu::Exporter::MARC;
use XML::LibXML;
use Test::More;

my $record = {
  record => [
            ['001', undef, undef, undef, 'rec002'],
            ['100', ' ', ' ', 'a', 'Slayer'],
            ['245', ' ', ' ',
                'a', 'Reign in Blood' ,
            ]
        ]
};

# XML exporter with default arguments

my $xml = undef;
my $exporter = Catmandu::Exporter::MARC->new(file => \$xml, type => 'XML');
$exporter->add($record);
$exporter->commit;
my $dom = XML::LibXML->load_xml( string => $xml );
ok($dom->version() eq '1.0', 'document version');
ok($dom->encoding() eq 'UTF-8', 'document encoding');
my $root = $dom->documentElement();
ok($root->localname eq 'collection', 'root collection');
ok($root->prefix eq 'marc', 'namespace prefix');


# XML exporter with arguments

$xml = undef;
$exporter = Catmandu::Exporter::MARC->new(file => \$xml, type => 'XML',  collection => 0, xml_declaration => 1);
$exporter->add($record);
$exporter->commit;
$dom = XML::LibXML->load_xml( string => $xml );
ok($dom->version() eq '1.0', 'document version');
ok($dom->encoding() eq 'UTF-8', 'document encoding');
$root = $dom->documentElement();
ok($root->localname eq 'record', 'root record');
ok($root->prefix eq 'marc', 'namespace prefix');

# XML exporter with arguments

$xml = undef;
$exporter = Catmandu::Exporter::MARC->new(file => \$xml, type => 'XML' , collection => 1, xml_declaration => 0);
$exporter->add($record);
$exporter->commit;
$dom = XML::LibXML->load_xml( string => $xml );
$root = $dom->documentElement();
ok($root->localname eq 'collection', 'root collection');
ok($root->prefix eq 'marc', 'namespace prefix');

done_testing;