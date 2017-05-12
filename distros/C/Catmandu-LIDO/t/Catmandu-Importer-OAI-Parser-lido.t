use strict;
use warnings;
use XML::LibXML;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::OAI::Parser::lido';
    use_ok $pkg;
}
require_ok $pkg;

my $parser = Catmandu::Importer::OAI::Parser::lido->new;

ok $parser , 'got a parser';

my $dom = XML::LibXML->load_xml(location => 't/data/yale.xml');

ok $dom , 'got a DOM';

my $perl = $parser->parse($dom);

ok $perl , 'parsed the data';

ok $perl->{_metadata}->{administrativeMetadata} , 'got lido';

done_testing;
