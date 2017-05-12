use strict;
use warnings;
use Test::More;
use Test::Exception;
use utf8;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::LIDO';
    use_ok $pkg;
}
require_ok $pkg;

my $importer = Catmandu::Importer::LIDO->new(file => 't/data/primavera.lido.org.xml');

ok $importer , 'got an importer';

my $record = $importer->first;

ok $record , 'got a record';

use Data::Dumper;

my $title = $record->{descriptiveMetadata}
                   ->[1]
                   ->{objectIdentificationWrap}
                   ->{titleWrap}
                   ->{titleSet}
                   ->[0]
                   ->{appellationValue}
                   ->[0]
                   ->{_};

is $title , 'La Primavera / Der Frühling' , 'encoding test';

done_testing;
