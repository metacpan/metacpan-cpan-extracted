use strict;
use warnings;
use Test::More;

use XML::Struct::Writer;

use_ok('Catmandu::Exporter::XML');

my $out = "";
my $exporter = Catmandu::Exporter::XML->new( file => \$out );

$exporter->add( [ foo => { bar => 'doz' }, ['&'] ] );
is $exporter->count, 1, 'count';

$exporter->add( [ foo => {}, ['<'] ] );
is $exporter->count, 2, 'count';

my $xml = <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<foo bar="doz">&amp;</foo>
<?xml version="1.0" encoding="UTF-8"?>
<foo>&lt;</foo>
XML

is $out, $xml, 'export multiple documents';

$out = "";
$exporter = Catmandu::Exporter::XML->new( 
    attributes => 0, pretty => 1, xmldecl => 0,
    file => \$out
);
$exporter->add( [ foo => [ [ bar => ['doz'] ] ] ] );
$xml = <<XML;
<foo>
  <bar>doz</bar>
</foo>
XML
is $out, $xml, 'export with configuration';

$out = "";
$exporter = Catmandu::Exporter::XML->new(
    file => \$out, xmldecl => 0, field => 'xml'
);
$exporter->add( { xml => [ foo => { bar => 23 } ] } );
is $out, "<foo bar=\"23\"/>\n", 'export from field';

use File::Temp qw(tempdir);
my $dir = tempdir();

$exporter = Catmandu::Exporter::XML->new( directory => $dir, field => '_xml' );
$exporter->add_many([
    { _id => 'foo', _xml => [ foo => {} ] },
    { _id => 'bar.xml', _xml => [ bar => {} ] },
]);
ok(-e "$dir/foo.xml" and -e "$dir/bar.xml", 'export to directory');
$xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<foo/>\n";
$out = do { local (@ARGV, $/) = "$dir/foo.xml"; <> };
is $out, $xml, 'exported to multiple files';

done_testing;
