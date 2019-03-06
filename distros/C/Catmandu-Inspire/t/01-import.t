use strict;
use warnings FATAL => 'all';
use Test::More;
use Catmandu::Importer::Inspire;

SKIP: {
    skip("No network. Set NETWORK_TEST to run these tests.", 3)
        unless $ENV{NETWORK_TEST};

    my $pkg = "Catmandu::Importer:Inspire";

    my $imp = $pkg->new( doi => '10.1088/1126-6708/2009/03/112', );
    is( $imp->count, 1, "count ok" );

    my $imp2 = $pkg->new(
        fmt => 'marc',
        id  => '811388',
    );
    is( $imp2->count, 1, "count ok" );

    my $imp3 = $pkg->new( query => "quark", limit => 50 );
    is( $imp3->count, 50, "count ok" );

    foreach my $fmt ( ( "endnote", "nlm", "marc", "dc" ) ) {
        my $imp4 = $pkg->new( query => "quark", limit => 40, fmt => $fmt );
        is( $imp4->count, 40, "count ok" );
    }
}

done_testing;
