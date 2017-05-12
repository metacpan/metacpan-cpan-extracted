use strict;
use CGI::Wiki::Plugin::Locator::Grid;
use CGI::Wiki::TestLib;
use Test::More;

my $iterator = CGI::Wiki::TestLib->new_wiki_maker;

unless ( $iterator->number ) {
    plan skip_all => "No backends configured";
    exit 0;
}

plan tests => ( $iterator->number * 3 );

while ( my $wiki = $iterator->new_wiki ) {

    my $locator = CGI::Wiki::Plugin::Locator::Grid->new(
        x => "easting",
        y => "northing",
    );
    isa_ok( $locator, "CGI::Wiki::Plugin::Locator::Grid" );
    $wiki->register_plugin( plugin => $locator );

    $wiki->write_node( "11", "grid point", undef,
                       { easting => 1000, northing => 1000 }
                     ) or die "Can't write node";

    $wiki->write_node( "12", "grid point", undef,
                       { easting => 1000, northing => 2000 }
                     ) or die "Can't write node";

    my ($x, $y) = $locator->coordinates( node => "11" );
    is_deeply( [ $x, $y ], [ 1000, 1000 ],
               "->coordinates works with different names" );

    my $distance = $locator->distance( from_node => "11",
                                       to_node   => "12" );
    is( $distance, 1000, "...so does ->distance" );
}


