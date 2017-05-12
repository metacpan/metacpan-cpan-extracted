use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::SRU;
use Catmandu::Importer::SRU::Parser::marcxml;
require 't/lib/MockFurl.pm';

my %attrs = (
    base => 'http://www.unicat.be/sru',
    query => 'marcxml.xml',
    recordSchema => 'marcxml',
    furl => MockFurl->new,
);

my $importer = Catmandu::Importer::SRU->new(%attrs);

isa_ok($importer, 'Catmandu::Importer::SRU');
can_ok($importer, 'each');
is($importer->url, 'http://www.unicat.be/sru?version=1.1&operation=searchRetrieve&query=marcxml.xml&recordSchema=marcxml&startRecord=1&maximumRecords=10');

my $marcparser = Catmandu::Importer::SRU::Parser::marcxml->new;
my @parsers = ( 
    'marcxml',
    '+Catmandu::Importer::SRU::Parser::marcxml',
    $marcparser,
    sub { $marcparser->parse($_[0]); }
);

foreach my $parser (@parsers) {
    my $importer = Catmandu::Importer::SRU->new(%attrs, parser => $parser);
    ok (my $obj = $importer->first , 'parse marc');
    ok (exists $obj->{_id} , 'marc has _id');
    ok (exists $obj->{record} , 'marc as record');
}

%attrs = (
    base => 'http://www.unicat.be/sru',
    query => 'test',
    recordSchema => 'marcxml',
    furl => MockFurlMany->new,
);

$importer = Catmandu::Importer::SRU->new(%attrs);
isa_ok($importer, 'Catmandu::Importer::SRU');
can_ok($importer, 'each');
ok (scalar @{$importer->to_array()} == 23, 'get all records');


done_testing;
