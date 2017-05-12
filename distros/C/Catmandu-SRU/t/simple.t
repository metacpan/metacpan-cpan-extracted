use strict;
use Test::More;

use Catmandu::Importer::SRU;
require 't/lib/MockFurl.pm';

my %options = (
    base   => 'http://example.org/',
    query  => 'sru_oai_dc.xml',
    furl   => MockFurl->new,
    parser => 'simple',
);

ok my $importer = Catmandu::Importer::SRU->new(%options);

ok my $record = $importer->first;
is_deeply $record->{recordData}->{dc}->{contributor}, ['Alice','Bob'];

# simple as default option
delete $options{parser};
is_deeply(Catmandu::Importer::SRU->new(%options)->first, $record);

done_testing;
