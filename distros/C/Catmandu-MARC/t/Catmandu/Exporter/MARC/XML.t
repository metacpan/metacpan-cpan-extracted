#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Exporter::MARC;
use XML::XPath;
use XML::LibXML;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::MARC::XML';
    use_ok $pkg;
}

require_ok $pkg;

my $xml = undef;

my $exporter = Catmandu::Exporter::MARC->new(file => \$xml, type=> 'XML' , collection => 0);

ok $exporter , 'got an MARC/XML exporter';

ok $exporter->add({
  record => [
            ['001', undef, undef, undef, 'rec001'],
            ['100', ' ', ' ', 'a', 'Davis, Miles'],
            ['245', ' ', ' ',
                'a', 'Sketches in Blue' ,
            ],
            ['500', ' ', ' ', 'a', undef],
            ['501', ' ', ' ' ],
            ['502', ' ', ' ', 'a', undef, 'b' , 'ok'],
            ['503', ' ', ' ', 'a', ''],
            ['504', ' ', ' ', '=', 'test'],
        ]
});

ok $exporter->commit;

my $xp;
ok($xp = XML::XPath->new(xml => $xml), "parse XML");
ok($xp->findvalue('/marc:record/marc:controlfield[@tag="001"]') eq 'rec001','test 001');
ok($xp->findvalue('/marc:record/marc:datafield[@tag="245"]/marc:subfield[@code="a"]') eq 'Sketches in Blue','test 245');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="500"]') ,'skipped 500 - only empty subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="501"]') ,'skipped 501 - no subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="502"]/marc:subfield[@code="a"]') ,'skipped 502a - empty subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="503"]/marc:subfield[@code="a"]') ,'skipped 503a - empty subfields');
ok($xp->exists('/marc:record/marc:datafield[@tag="504"]/marc:subfield[@code="="]') ,'found 504= - special subfields');

$xml = undef;

$exporter = Catmandu::Exporter::MARC->new(file => \$xml, type=> 'XML', record_format => 'MARC-in-JSON', collection => 0);

ok($exporter, "create exporter MARC-in-JSON");

ok $exporter->add({
  fields => [
  	{ '001' => 'rec001' } ,
  	{ '100' => { 'subfields' => [ { 'a' => 'Davis, Miles'}], 'ind1' => ' ', 'ind2' => ' '}} ,
  	{ '245' => { 'subfields' => [ { 'a' => 'Sketches in Blue'}], 'ind1' => ' ', 'ind2' => ' '}} ,
  	{ '500' => { 'subfields' => [ { 'a' => undef }] , 'ind1' => ' ', 'ind2' => ' '}} ,
  	{ '501' => { 'ind1' => ' ', 'ind2' => ' ' }} ,
  	{ '502' => { 'subfields' => [ { 'a' => undef} , { 'b' , 'ok' } ] , 'ind1' => ' ', 'ind2' => ' ' } } ,
    { '503' => { 'subfields' => [ { 'a' => '' }] , 'ind1' => ' ', 'ind2' => ' '}} ,
    { '504' => { 'subfields' => [ { '=' => 'test' }] , 'ind1' => ' ', 'ind2' => ' '}} ,
  ]
});

ok $exporter->commit;

ok($xp = XML::XPath->new(xml => $xml), "parse XML");
ok($xp->findvalue('/marc:record/marc:controlfield[@tag="001"]') eq 'rec001','test 001');
ok($xp->findvalue('/marc:record/marc:datafield[@tag="245"]/marc:subfield[@code="a"]') eq 'Sketches in Blue','test 245');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="500"]') ,'skipped 500 - only empty subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="501"]') ,'skipped 501 - no subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="502"]/marc:subfield[@code="a"]') ,'skipped 502a - empty subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="503"]/marc:subfield[@code="a"]') ,'skipped 503a - empty subfields');
ok($xp->exists('/marc:record/marc:datafield[@tag="504"]/marc:subfield[@code="="]') ,'found 504= - special subfields');

{
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
}

done_testing;
