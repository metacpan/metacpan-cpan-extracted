package Amazon::MWS::FulfillmentOutbound;

use Amazon::MWS::Routines qw(:all);

my $fulfillment_service = '/FulfillmentOutboundShipment/2010-10-01/';

define_api_method GetServiceStatus =>
    version => '2010-10-01',
    raw_body => 0,
    service => "$fulfillment_service",
    module_name => 'Amazon::MWS::FulfillmentOutbound',
    parameters => {},
    respond => sub {
        my $root = shift;
        return $root->{Status};
   };

1;
