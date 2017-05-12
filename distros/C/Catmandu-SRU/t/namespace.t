use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::SRU;
use Catmandu::Importer::SRU::Parser::marcxml;
require 't/lib/MockFurl.pm';

my %attrs = (
    base => 'http://www.unicat.be/sru',
    query => 'marcxml_ns.xml',
    recordSchema => 'marcxml',
    parser => 'marcxml',
    furl => MockFurl->new,
);

my $importer = Catmandu::Importer::SRU->new(%attrs);
my $records = $importer->to_array();
for my $record ( @{$records} ) {
    ok (exists $record->{_id}, 'marc has _id');
    ok (exists $record->{record}, 'marc has record');
    is_deeply ($record->{record}->[0], ['LDR', ' ', ' ', '_', '00785nas a2200277 c 4500'], 'marc has leader');
    is_deeply ($record->{record}->[1], ['001', ' ', ' ', '_', '987874829'], 'marc has controlfield');
    is_deeply ($record->{record}->[-1], ['245', '1', '0', 'a', 'Code4Lib journal', 'h', 'Elektronische Ressource', 'b', 'C4LJ'], 'marc has datafield');
}

done_testing;
