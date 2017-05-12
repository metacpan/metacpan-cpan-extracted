use strict;
use warnings;
use Catmandu::Importer::JSON;
use IO::String;
use Test::More;
use Test::Exception;
use utf8;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::LIDO';
    use_ok $pkg;
}
require_ok $pkg;

my $importer = Catmandu::Importer::JSON->new(file => 't/data/primavera.lido.org.json', line_delimited => 0);

my $xml;
my $io = IO::String->new($xml);

my $exporter = Catmandu::Exporter::LIDO->new(fh => $io);

ok $exporter, 'got an exporter';

ok $exporter->add_many($importer) , 'add_many';

ok $exporter->commit , 'commit';

like $xml , qr{.*La Primavera / Der Frühling.*} , 'encoding test';

done_testing;
