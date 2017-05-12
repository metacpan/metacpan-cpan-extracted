use strict;
use warnings;

use Test::More;
use Test::Warnings ':all';

use Catmandu::Importer::MARC;
use Catmandu::Exporter::MARC;

# USMARC as alias for ISO
my $importer;
like( warning { $importer = Catmandu::Importer::MARC->new( file => "t/camel.mrc", type => "USMARC" ) }, qr/is deprecated/i, 'deprecation warning importer');
ok($importer, "create importer USMARC");
my $records = $importer->to_array();
ok( @$records == 10, "import records" );

my $xml = '';
my $exporter;
like( warning { $exporter = Catmandu::Exporter::MARC->new( file => \$xml, type => "USMARC" ) }, qr/is deprecated/i, 'deprecation warning exporter');
ok($exporter, "create exporter USMARC");
$exporter->add({
  _id => '1' ,
  record => [
            ['001', undef, undef, '_', 'rec001'],
            ['100', ' ', ' ', 'a', 'Davis, Miles' , 'c' , 'Test'],
        ]
});
ok($xml =~ /^00080     2200049   4500001000700000100002300007rec001  aDavis, MilescTest$/, "export records");

done_testing();