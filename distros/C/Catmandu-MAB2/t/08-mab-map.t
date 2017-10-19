use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MAB2;
use Catmandu::Fix;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::mab_map';
    use_ok $pkg;
}
require_ok $pkg;

my $fixer = Catmandu::Fix->new( fixes => [q|mab_map('00 ', test)|] );
my $importer
    = Catmandu::Importer::MAB2->new( file => './t/mab2.xml', type => "XML" );

eval { $fixer->fix( $importer->first ) };
ok $@, 'got exception'; 

done_testing;
