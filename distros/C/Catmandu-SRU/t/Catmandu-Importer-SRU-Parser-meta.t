use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::SRU;
use utf8;

require 't/lib/MockFurl.pm';

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::SRU::Parser::meta';
    use_ok $pkg;
}

require_ok $pkg;

my $importer = Catmandu::Importer::SRU->new(
    base   => 'http://example.org/',
    query  => 'meta.xml',
    furl   => MockFurl->new,
    parser => 'meta',
);

is_deeply {
    version => '1.1',
    numberOfRecords => '23',
    resultSetId => '1',
    resultSetIdleTime => '5000',
    nextRecordPosition => '11',
    extraResponseData => {
        accountOf => 'Zeitschriftendatenbank (ZDB)',
        'test:test' => 'test'
    },
    diagnostics => [
        {
            uri => 'info:srw/diagnostic/1/38',
            message => 'Whatever',
            details => '10',
        }, {
            uri => 'foo:bar',
        }
    ],
    echoedSearchRetrieveRequest => {
        query        => 'tit=soil and biology',
        recordSchema => 'MARC21-xml',
        version      => '1.1',
        xQuery       => ''
   },
   requestUrl => 'http://example.org/?version=1.1&operation=searchRetrieve&query=meta.xml&recordSchema=dc&startRecord=1&maximumRecords=10',
}, $importer->next, 'SRU SearchRetrieve Response Parameters';
ok !$importer->next, 'it\'s only one record';

done_testing;
