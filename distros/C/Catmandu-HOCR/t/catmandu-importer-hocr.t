use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use File::Spec;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::HOCR';
    use_ok $pkg;
}
require_ok $pkg;

{
    my $importer;

    lives_ok(sub {

        $importer = $pkg->new( file => File::Spec->catfile("t","html","ossa.html") );

    },"importer created");

    my $r = $importer->next();

    is_deeply($r, {
        h => 102,
        page => 1,
        page_h => 3316,
        page_w => 2904,
        page_x => 0,
        page_y => 0,
        text => "L’OSSATURE MÉTALLIQUE",
        w => 1578,
        x => 651,
        y => 517
    }, "record 1 ok");

    $r = $importer->next();

    is_deeply($r, {
        h => 44,
        page => 1,
        page_h => 3316,
        page_w => 2904,
        page_x => 0,
        page_y => 0,
        text => "BULLETIN DE DOCUMENTATION. NUMÉRO U MARS 1932",
        w => 1583,
        x => 649,
        y => 640
    });

}

# text is enclosed within element strong
{

    my $importer;

    lives_ok(sub {

        $importer = $pkg->new( file => File::Spec->catfile("t","html","strong.html") );

    },"importer created");

    my $r = $importer->next();

    is_deeply($r, {
        h => 32,
        page => 1,
        page_h => 3820,
        page_w => 2737,
        page_x => 0,
        page_y => 0,
        text => "stormsoldaten onzen schoenen strijdzang zingen, en nog",
        w => 738,
        x => 209,
        y => 292
    }, "strong.html: record 1 ok");

}

done_testing;
