use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::SRU;
use Catmandu::Importer::SRU::Parser::marcxml;
use lib 't/lib';
use MockFurl;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::SRU';
    use_ok $pkg;
}

require_ok $pkg;

my %options = (
    base   => 'http://example.org/',
    query  => 'sru_oai_dc.xml',
    furl   => MockFurl->new,
    parser => 'struct',
);

ok my $importer = Catmandu::Importer::SRU->new(%options);
my $rec      = $importer->next;
my $expected = [
    'oai_dc:dc',
    {
        'xmlns:dc'     => 'http://purl.org/dc/elements/1.1/',
        'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/'
    },
    [
        ['dc:title',       {}, ['Sample Title']],
        ['dc:contributor', {}, ['Alice']],
        ['dc:contributor', {}, ['Bob']],
        [
            'dc:date', {'xmlns:srw_dc' => 'info:srw/schema/1/dc-schema'},
            ['2013']
        ]
    ]
];

is_deeply $rec, $expected, 'first';

$rec      = $importer->next;
$expected = [
    'oai_dc:dc',
    {
        'xmlns:dc'     => 'http://purl.org/dc/elements/1.1/',
        'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/'
    },
    [['dc:title', {}, ['Another Title']]]
];

is_deeply $rec, $expected, 'second';

my $reader = XML::Struct::Reader->new(ns => 'strip', attributes => 0);
$options{parser} = sub {
    $reader->readDocument(
        XML::LibXML::Reader->new(string => $_[0]->{recordData}->toString));
};
$importer = Catmandu::Importer::SRU->new(%options);
$importer->next;
$rec      = $importer->next;
$expected = [dc => [['title' => ['Another Title']]]];

is_deeply $rec, $expected, 'reader options';

done_testing;
