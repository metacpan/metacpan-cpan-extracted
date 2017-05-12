#!/usr/bin/perl

use strict;
use warnings;

use Catmandu::Exporter::MARC;
use XML::XPath;
use Test::Simple tests => 25;

my $xml = undef;

my $exporter = Catmandu::Exporter::MARC->new(file => \$xml, type=> 'XML' , collection => 0);

ok($exporter, "create exporter XML");

$exporter->add({
  record => [
            ['001', undef, undef, undef, 'rec001'],
            ['100', ' ', ' ', 'a', 'Davis, Miles'],
            ['245', ' ', ' ',
                'a', 'Sketches in Blue' ,
            ],
            ['500', ' ', ' ', 'a', undef],
            ['501', ' ', ' ' ],
            ['502', ' ', ' ', 'a', undef, 'b' , 'ok'],
            ['503'. ' ', ' ', 'a', ''],
        ]
});

$exporter->commit;

my $xp;
ok($xp = XML::XPath->new(xml => $xml), "parse XML");
ok($xp->findvalue('/marc:record/marc:controlfield[@tag="001"]') eq 'rec001','test 001');
ok($xp->findvalue('/marc:record/marc:datafield[@tag="245"]/marc:subfield[@code="a"]') eq 'Sketches in Blue','test 245');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="500"]') ,'skipped 500 - only empty subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="501"]') ,'skipped 501 - no subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="502"]/marc:subfield[@code="a"]') ,'skipped 502a - empty subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="503"]/marc:subfield[@code="a"]') ,'skipped 503a - empty subfields');

$xml = undef;
$exporter = Catmandu::Exporter::MARC->new(file => \$xml, type=> 'XML', record_format => 'MARC-in-JSON', collection => 0);

ok($exporter, "create exporter MARC-in-JSON");

$exporter->add({
  fields => [
  	{ '001' => 'rec001' } ,
  	{ '100' => { 'subfields' => [ { 'a' => 'Davis, Miles'}], 'ind1' => ' ', 'ind2' => ' '}} ,
  	{ '245' => { 'subfields' => [ { 'a' => 'Sketches in Blue'}], 'ind1' => ' ', 'ind2' => ' '}} ,
  	{ '500' => { 'subfields' => [ { 'a' => undef }] , 'ind1' => ' ', 'ind2' => ' '}} ,
  	{ '501' => { 'ind1' => ' ', 'ind2' => ' ' }} ,
  	{ '502' => { 'subfields' => [ { 'a' => undef} , { 'b' , 'ok' } ] , 'ind1' => ' ', 'ind2' => ' ' } } ,
    { '503' => { 'subfields' => [ { 'a' => '' }] , 'ind1' => ' ', 'ind2' => ' '}} ,
  ]
});

ok($xp = XML::XPath->new(xml => $xml), "parse XML");
ok($xp->findvalue('/marc:record/marc:controlfield[@tag="001"]') eq 'rec001','test 001');
ok($xp->findvalue('/marc:record/marc:datafield[@tag="245"]/marc:subfield[@code="a"]') eq 'Sketches in Blue','test 245');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="500"]') ,'skipped 500 - only empty subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="501"]') ,'skipped 501 - no subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="502"]/marc:subfield[@code="a"]') ,'skipped 502a - empty subfields');
ok(! $xp->exists('/marc:record/marc:datafield[@tag="503"]/marc:subfield[@code="a"]') ,'skipped 503a - empty subfields');

$xml = '';
$exporter = Catmandu::Exporter::MARC->new(file => \$xml, type=> 'ALEPHSEQ' , skip_empty_subfields => 1);

ok($exporter, "create exporter ALEPHSEQ");

$exporter->add({
  _id => '1' ,
  record => [
            ['001', undef, undef, '_', 'rec001'],
            ['100', ' ', ' ', 'a', 'Davis, Miles' , 'c' , 'Test'],
            ['245', ' ', ' ',
                'a', 'Sketches in Blue' ,
            ],
            ['500', ' ', ' ', 'a', undef],
            ['501', ' ', ' ' ],
            ['502', ' ', ' ', 'a', undef, 'b' , 'ok'],
            ['503'. ' ', ' ', 'a', ''],
        ]
});


ok($xml =~ /^000000001/, 'test id');
ok($xml =~ /000000001 100   L \$\$aDavis, Miles\$\$cTest/, 'test subfields');
ok($xml !~ /000000001 500/, 'test skip empty subfields');

$xml = '';
$exporter = Catmandu::Exporter::MARC->new(
                  file => \$xml,
                  type=> 'ALEPHSEQ',
                  record_format => 'MARC-in-JSON',
                  skip_empty_subfields => 1
);

ok($exporter, "create exporter ALEPHSEQ for MARC-in-JSON");

$exporter->add({
  _id => '1',
  fields => [
    { '001' => 'rec001' } ,
    { '100' => { 'subfields' => [ { 'a' => 'Davis, Miles'} , { 'c' => 'Test'}], 'ind1' => ' ', 'ind2' => ' '}} ,
    { '245' => { 'subfields' => [ { 'a' => 'Sketches in Blue'}], 'ind1' => ' ', 'ind2' => ' '}} ,
    { '500' => { 'subfields' => [ { 'a' => undef }] , 'ind1' => ' ', 'ind2' => ' '}} ,
    { '501' => { 'ind1' => ' ', 'ind2' => ' ' }} ,
    { '502' => { 'subfields' => [ { 'a' => undef} , { 'b' , 'ok' } ] , 'ind1' => ' ', 'ind2' => ' ' } } ,
    { '503' => { 'subfields' => [ { 'a' => '' }] , 'ind1' => ' ', 'ind2' => ' '}} ,
    { '540' => { 'subfields' => [ { 'a' => "\nabcd\n" }] , 'ind1' => ' ', 'ind2' => ' '}}
  ]
});

ok($xml =~ /^000000001/, 'test id');
ok($xml =~ /000000001 100   L \$\$aDavis, Miles\$\$cTest/, 'test subfields');
ok($xml !~ /000000001 500/, 'test skip empty subfields');
ok($xml =~ /000000001 540   L \$\$aabcd/, 'test skip newlines');
