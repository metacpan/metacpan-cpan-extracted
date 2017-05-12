package main;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Satpass;
use Test::More 0.88;

eval {
    require Geo::Coder::OSM;
    1;
} or do {
    plan skip_all => 'Geo::Coder::OSM not available';
    exit;
};

eval {
    require LWP::UserAgent;
    1;
} or plan skip_all => 'LWP::UserAgent not available';

{
    my $ua = LWP::UserAgent->new ();
    no warnings qw{ once };
    my $src = $Geo::Coder::OSM::SOURCES{osm}
	or plan skip_all => 'Can not determine OSM URL';
    my $rslt = $ua->get ( $src );
    $rslt->is_success()
	or plan skip_all => "$src not reachable";
}

My::Module::Satpass::satpass( *DATA );

1;
__END__

## -skip not_available ('Geo::Coder::OSM') || not_reachable ('http://rpc.geocoder.us/')

set country us
set autoheight 0
geocode '1600 Pennsylvania Ave NW, Washington DC'
-data <<eod
set location '1600 Pennsylvania Ave NW, Washington DC'
set latitude 38.897700
set longitude -77.036553
eod
-test geocode U.S. location via OSM

# BELOW HERE NOT TESTED BECAUSE GEOCODER.CA REQUIRES REGISTRATION FOR
# THEIR FREE PORT.

-end

-skip not_available ('XML::Parser') || not_reachable ('http://rpc.geocoder.ca/')

set country ca
set autoheight 0
geocode '80 Wellington Street, Ottawa ON'
-data <<eod
set location '80 Wellington Street, Ottawa ON'
set latitude 45.423388
set longitude -75.697786
eod
-test geocode Canadian location via http://rpc.geocoder.ca/
