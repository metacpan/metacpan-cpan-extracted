use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use File::Spec;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::PDFPages';
    use_ok $pkg;
}

require_ok $pkg;

my $importer;

lives_ok(sub {

    $importer = $pkg->new( file => File::Spec->catfile("t","pdf","greek.pdf") );

},"importer created");

my $array;

lives_ok(sub{

    $array = $importer->to_array();

},"imported pdf");

is_deeply($array,[
    {
        height  =>  842,
        label   =>  '1',
        text    =>  "ἄνδρα μοι ἔννεπε, μοῦσα, πολύτροπον, ὃς μάλα πολλὰ",
        width   =>  595
    }
],"pdf read successfully");

done_testing 5;
