#!perl

use strict;
use warnings;
use Test::More;

use Catmandu;
use XML::XPath;

BEGIN {
    use_ok 'Catmandu::Exporter::PNX';
}

require_ok 'Catmandu::Exporter::PNX';

my $xml = undef;

my $importer = Catmandu->importer('YAML', file => 't/test.yml');
my $exporter = Catmandu->exporter('PNX',file => \$xml);

ok $exporter , 'got a exporter';

my $num = $exporter->add_many($importer);

is $num , 2 , 'exported 2 records';

ok $exporter->commit , 'can commit';

like $xml , qr/^<\?xml/ , 'got XML';

my $xp;
ok $xp = XML::XPath->new(xml => $xml), "parse XML";

is $xp->findvalue('/OAI-PMH/ListRecords/record[1]/metadata/record/control/sourcerecordid') , '004400000', 'test 001';
is $xp->findvalue('/OAI-PMH/ListRecords/record[1]/metadata/record/links/openurlfulltext') , '$$Topenurlfull_journal', 'test 002';
is $xp->findvalue('/OAI-PMH/ListRecords/record[2]/header[@status="deleted"]/identifier') , 'undefined', 'test 003';

done_testing 10;
