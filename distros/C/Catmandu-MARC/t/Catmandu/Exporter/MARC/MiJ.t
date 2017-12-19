#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Exporter::MARC;
use JSON::XS;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::MARC::MiJ';
    use_ok $pkg;
}

require_ok $pkg;

my $json = undef;

my $exporter = Catmandu::Exporter::MARC->new(file => \$json, type=> 'MiJ' , skip_empty_subfields => 1);

ok $exporter , 'got an MARC/MiJ exporter';

ok $exporter->add({
  _id => '1' ,
  record => [
            ['001', undef, undef, '_', 'rec001'],
            ['100', ' ', ' ', 'a', 'Davis, Miles' , 'c' , 'Test'],
            ['245', ' ', ' ',
                'a', 'Sketches in Blue' ,
            ],
            ['500', ' ', ' ', 'a', "test"],
            ['501', ' ', ' ', 'a', "test"],
            ['502', ' ', ' ', 'a', "bla", 'b' , 'ok'],
        ]
}) , 'add a record';

ok $exporter->commit , 'commit';

my $perl = decode_json $json;

ok $perl , 'decode json';

done_testing;
