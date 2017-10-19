use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::SRU;
use Catmandu::Importer::SRU::Parser::mabxml;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockFurl;


my %attrs = (
    base => 'http://www.unicat.be/sru',
    query => 'sru_mabxml.xml',
    recordSchema => 'mabxml',
    furl => MockFurl->new,
);

my $importer = Catmandu::Importer::SRU->new(%attrs);
isa_ok($importer, 'Catmandu::Importer::SRU');
can_ok($importer, 'each');
is($importer->url, 'http://www.unicat.be/sru?version=1.1&operation=searchRetrieve&query=sru_mabxml.xml&recordSchema=mabxml&startRecord=1&maximumRecords=10');

my $mabparser = Catmandu::Importer::SRU::Parser::mabxml->new;

my @parsers = ( 
    'mabxml',
    '+Catmandu::Importer::SRU::Parser::mabxml',
    $mabparser,
    sub { $mabparser->parse($_[0]); }
);

foreach my $parser (@parsers) {
    my $importer = Catmandu::Importer::SRU->new(%attrs, parser => $parser);
    ok (my $obj = $importer->first, 'parse mabxml');
    ok (exists $obj->{_id} , 'mabxml has _id');
    ok (exists $obj->{record} , 'mabxml as record');
}

done_testing;
