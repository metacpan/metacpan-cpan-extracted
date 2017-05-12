use strict;
use warnings;
use Test::More;

use Catmandu;
use Catmandu::Fix;
use Catmandu::Importer::PICA;

my $fixer = Catmandu::Fix->new(fixes => ['pica_map("007G0", "subfield_zero")','pica_map("007Gc", "subfield_c")','remove_field("record")','remove_field("_id")']);
my $importer = Catmandu::Importer::PICA->new(file => "./t/files/picaxml.xml", type=> "XML");
my $records = $fixer->fix($importer)->to_array;

is( $records->[0]->{'subfield_c'}, 'GBV', 'get subfield c' );
is( $records->[0]->{'subfield_zero'}, '658700774', 'get subfield 0' );

done_testing();