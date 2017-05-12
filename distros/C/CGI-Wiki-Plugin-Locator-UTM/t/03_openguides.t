use strict;

use Test::More;

BEGIN {
    eval "use OpenGuides";
    if (!$@) {
        eval "use DBD::SQLite";
    }

    if ($@) {
        plan skip_all => $@;
    }
    else {
        plan tests => 10;
    }
}

use OpenGuides::Config;
use CGI::Wiki::Setup::SQLite;
use CGI::Wiki::Plugin::Locator::UTM;

my @testdata1 = (
    {},
    {
        latitude => [ 51.521319 ],
        longitude => [ -0.102416 ],
    },
    {
        latitude => [ 53.333333 ],  # Coordinates for Dublin
        longitude => [ -6.25 ],     # courtesy of www.infoplease.com
    },
    {
        latitude => [ 51.521319 ],
        longitude => [ -0.102416 ],
    } );
    
my @expected1 = (
    {},
    {
        latitude => [ 51.521319 ],
        longitude => [ -0.102416 ],
        os_x => [ 531686 ],
        os_y => [ 182077 ],
    },
    {
        latitude => [ 53.333333 ],
        longitude => [ -6.25 ],
        osie_x => [ 316616 ],
        osie_y => [ 232930 ],
    },
    {
        latitude => [ 51.521319 ],
        longitude => [ -0.102416 ],
        easting => [ 701016 ],
        northing => [ 5711780 ],
    } );

for my $geo (1..3) {
    my $config = OpenGuides::Config->new( file => "t/wiki$geo.conf" );
    my $dbname = $config->dbname;
    CGI::Wiki::Setup::SQLite::setup($dbname,'','','');

    #01
    ok( (-e $dbname), 'Test guide created' );
    
    my $guide = OpenGuides->new( config => $config );
    my $wiki = $guide->wiki;
    
    my $locator = CGI::Wiki::Plugin::Locator::UTM->new;
    #02
    isa_ok( $locator, 'CGI::Wiki::Plugin::Locator::UTM') ;
    
    $wiki->register_plugin( plugin => $locator );

    $locator->og_config( $config );

    if ($geo == 3) {
        #02a
        is( $locator->{ellipsoid}, 'WGS-84', 'Type 3 has ellipsoid');
    }

    my %metadata = %{$testdata1[$geo]};
    my $node = 'test';
    my $content = 'test data';

    $locator->pre_write( $node, $content, \%metadata );

    my ($x,$y) = @{$CGI::Wiki::Plugin::Locator::UTM::geo_mechanism[$geo]}
                {'x','y'};

    #03
    is_deeply( \%metadata, $expected1[$geo], 
        'Metadata added when lat/long given' );
    
    $wiki->store->dbh->disconnect;

    unlink $dbname;
}
