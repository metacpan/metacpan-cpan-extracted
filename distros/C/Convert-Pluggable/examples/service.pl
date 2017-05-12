#!/usr/bin/env perl

use Dancer2;

set serializer => 'JSON';   # Dancer2::Serializer::JSON;

use lib '../lib';
use Convert::Pluggable;

my $data_file = '../data/units.json';

# tell C::P where to get the data for the conversions:
my $c = new Convert::Pluggable( data_file => $data_file );
# or, ye olde waye:
# my $c = Convert::Pluggable->new();

#
# curl http://localhost:3000/convert/3/kg/ounces
#
get '/convert/:factor/:from/:to' => sub {
    my $conversion = $c->convert({
        'factor'    => params->{factor},
        'from_unit' => params->{from},
        'to_unit'   => params->{to},
    });

    return {
        result => $conversion,
    };
};
