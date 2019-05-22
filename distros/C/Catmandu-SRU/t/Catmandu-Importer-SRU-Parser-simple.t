use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::SRU;
use utf8;
use lib 't/lib';
use MockFurl;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::SRU::Parser::simple';
    use_ok $pkg;
}

require_ok $pkg;

my %options = (
    base   => 'http://example.org/',
    query  => 'sru_oai_dc.xml',
    furl   => MockFurl->new,
    parser => 'simple',
);

ok my $importer = Catmandu::Importer::SRU->new(%options);

ok my $record = $importer->first;
is_deeply $record->{recordData}->{dc}->{contributor}, ['Alice', 'Bob'];

# simple as default option
delete $options{parser};
is_deeply(Catmandu::Importer::SRU->new(%options)->first, $record);

done_testing;
