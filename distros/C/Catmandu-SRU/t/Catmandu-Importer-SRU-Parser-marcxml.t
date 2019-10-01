use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::SRU;
use utf8;
use lib 't/lib';
use MockHTTPClient;
use MockHTTPClientMany;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::SRU::Parser::marcxml';
    use_ok $pkg;
}

require_ok $pkg;

my %attrs = (
    base         => 'http://www.unicat.be/sru',
    query        => 'marcxml.xml',
    recordSchema => 'marcxml',
    http_client  => MockHTTPClient->new,
);

my $importer = Catmandu::Importer::SRU->new(%attrs);

isa_ok($importer, 'Catmandu::Importer::SRU');
can_ok($importer, 'each');
is($importer->url,
    'http://www.unicat.be/sru?version=1.1&operation=searchRetrieve&query=marcxml.xml&recordSchema=marcxml&startRecord=1&maximumRecords=10'
);

my $marcparser = Catmandu::Importer::SRU::Parser::marcxml->new;
my @parsers    = (
    'marcxml', '+Catmandu::Importer::SRU::Parser::marcxml',
    $marcparser, sub {$marcparser->parse($_[0]);}
);

foreach my $parser (@parsers) {
    my $importer = Catmandu::Importer::SRU->new(%attrs, parser => $parser);
    ok(my $obj = $importer->first, 'parse marc');
    ok(exists $obj->{_id},         'marc has _id');
    ok(exists $obj->{record},      'marc as record');
}

note("Testing many response");
{
    my %attrs = (
        base         => 'http://www.unicat.be/sru',
        query        => 'test',
        recordSchema => 'marcxml',
        http_client  => MockHTTPClientMany->new,
    );

    my $importer = Catmandu::Importer::SRU->new(%attrs);
    isa_ok($importer, 'Catmandu::Importer::SRU');
    can_ok($importer, 'each');
    ok(scalar @{$importer->to_array()} == 23, 'get all records');
}

note("Testing namespace");
{
    my %attrs = (
        base         => 'http://www.unicat.be/sru',
        query        => 'marcxml_ns.xml',
        recordSchema => 'marcxml',
        parser       => 'marcxml',
        http_client  => MockHTTPClient->new,
    );

    my $importer = Catmandu::Importer::SRU->new(%attrs);
    my $records  = $importer->to_array();
    for my $record (@{$records}) {
        ok(exists $record->{_id},    'marc has _id');
        ok(exists $record->{record}, 'marc has record');
        is_deeply(
            $record->{record}->[0],
            ['LDR', ' ', ' ', '_', '00785nas a2200277 c 4500'],
            'marc has leader'
        );
        is_deeply(
            $record->{record}->[1],
            ['001', ' ', ' ', '_', '987874829'],
            'marc has controlfield'
        );
        is_deeply(
            $record->{record}->[-1],
            [
                '245', '1', '0', 'a', 'Code4Lib journal',
                'h', 'Elektronische Ressource',
                'b', 'C4LJ'
            ],
            'marc has datafield'
        );
    }
}

note("Testing namespace prefix");
{
    my %attrs = (
        base         => 'http://www.unicat.be/sru',
        query        => 'marcxml_ns_prefix.xml',
        recordSchema => 'marcxml',
        parser       => 'marcxml',
        http_client  => MockHTTPClient->new,
    );

    my $importer = Catmandu::Importer::SRU->new(%attrs);
    my $records  = $importer->to_array();

    is scalar @{$records}, 5, 'marc has 5 records';

    ok exists $records->[0]->{_id},    'marc has _id';
    ok exists $records->[0]->{record}, 'marc has record';
    is_deeply $records->[0]->{record}->[0],
        ['LDR', ' ', ' ', '_', '00000ndd a2200000 u 4500'], 'marc has leader';
    is_deeply $records->[0]->{record}->[1],
        ['001', ' ', ' ', '_', '004641415'], 'marc has controlfield';
    is_deeply $records->[0]->{record}->[-1],
        [
        '852',
        ' ',
        ' ',
        'a',
        'D-B',
        'c',
        'Mus.ms.autogr. Zelter, K. F. 17 (3)',
        'e',
        'Staatsbibliothek zu Berlin - Preußischer Kulturbesitz, Musikabteilung',
        'x',
        '30000655'
        ],
        'marc has datafield';
}

done_testing;
