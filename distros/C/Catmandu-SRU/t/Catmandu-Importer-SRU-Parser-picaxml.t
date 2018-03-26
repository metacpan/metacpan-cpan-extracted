use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::SRU;
use utf8;

require 't/lib/MockFurl.pm';

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::SRU::Parser::picaxml';
    use_ok $pkg;
}

require_ok $pkg;

my %options = (
    base   => 'http://example.org/',
    query  => 'picaxml.xml',
    furl   => MockFurl->new,
    parser => 'picaxml',
);

ok my $importer = Catmandu::Importer::SRU->new(%options);
ok my $record = $importer->next;

is $record->{_id}, '00903482X', 'PPN';
is_deeply ['002@', undef, '0', 'Tw'], $record->{record}->[5], 'fields';


done_testing;
