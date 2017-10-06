package Amazon::MWS::InboundShipment;

use Amazon::MWS::Routines qw(:all);

my $inbound_service = '/FulfillmentInboundShipment/2010-10-01';

define_api_method GetServiceStatus =>
    version => '2010-10-01',
    raw_body => 0,
    service => "$inbound_service",
    module_name => 'Amazon::MWS::InboundShipment',
    parameters => {},
    respond => sub {
        my $root = shift;
        return $root->{Status};
   };

define_api_method GetInboundGuidanceForASIN =>
    version => '2010-10-01',
    raw_body => 1,
    service => "$inbound_service",
    parameters => {
        ASINList        => {
             type       => 'ASINList',
             required   => 1
        },
	MarketplaceId   => { type => 'string', required=>1 },
    };

define_api_method GetInboundGuidanceForSKU =>
    version => '2010-10-01',
    raw_body => 1,
    service => "$inbound_service",
    parameters => {
        SellerSKUList   => {
             type       => 'SellerSKUList',
             required   => 1
        },
	MarketplaceId   => { type => 'string', required=>1 },
    };

define_api_method GetPrepInstructionsForASIN =>
    version => '2010-10-01',
    raw_body => 1,
    service => "$inbound_service",
    parameters => {
        ASINList        => {
             type       => 'ASINList',
             required   => 1
        },
        ShipToCountryCode   => { type => 'string', required=>1 },
    };

define_api_method GetPrepInstructionsForSKU =>
    version => '2010-10-01',
    raw_body => 1,
    service => "$inbound_service",
    parameters => {
        SellerSKUList   => {
             type       => 'SellerSKUList',
             required   => 1
        },
        ShipToCountryCode   => { type => 'string', required=>1 },
    };

define_api_method ListInboundShipments =>
    raw_body => 1,
    service => "$inbound_service",
    parameters => {
        ShipmentStatusList      => {
             required   => 1,
             type       => 'MemberList'
        },
        LastUpdatedAfter        => { type => 'datetime' },
        LastUpdatedBefore       => { type => 'datetime' }
    };

define_api_method ListInboundShipmentsByNextToken =>
    raw_body => 1,
    service => "$inbound_service",
    parameters => {
        NextToken => {
            type     => 'string',
            required => 1,
        },
    };

define_api_method ListInboundShipmentItems =>
    raw_body => 1,
    service => "$inbound_service",
    parameters => {
        ShipmentId => {
             required   =>      1,
             type       =>      'string',
        },
        LastUpdatedAfter        => { type => 'datetime' },
        LastUpdatedBefore       => { type => 'datetime' }
    };

define_api_method ListInboundShipmentItemsByNextToken =>
    raw_body => 1,
    service => "$inbound_service",
    parameters => {
        NextToken => {
            type     => 'string',
            required => 1,
        },
    };


define_api_method CreateInboundShipmentPlan =>
    version => '2010-10-01',
    raw_body => 1,
    method => 'POST',
    service => "$inbound_service",
    parameters => {
        LabelPrepPreference => { type => 'string' },
	'ShipFromAddress.Name' => { required => 1, type=>'string' },
	'ShipFromAddress.AddressLine1' => { required => 1, type=>'string' },
	'ShipFromAddress.City' => { required => 1, type=>'string' },
	'ShipFromAddress.StateOrProvinceCode' => { required => 1, type=>'string' },
	'ShipFromAddress.PostalCode' => { required => 1, type=>'string' },
	'ShipFromAddress.CountryCode' => { required => 1, type=>'string' },
	'ShipFromAddress.AddressLine2' => { type=>'string' },
	'ShipFromAddress.DistrictOrCounty' => { type=>'string' },
        'InboundShipmentPlanRequestItems' => {
		   array_names => ['SellerSKU','Quantity','ASIN','Condition'],
	           type => 'memberArray',
	}
    };	

define_api_method CreateInboundShipment =>
    version => '2010-10-01',
    raw_body => 1,
    method => 'POST',
    service => "$inbound_service",
    parameters => {
	ShipmentId => { type => 'string' },
	'InboundShipmentHeader.ShipmentName' => { required => 1, type => 'string' },
	'InboundShipmentHeader.ShipFromAddress.Name' => { required => 1, type => 'string' },
	'InboundShipmentHeader.ShipFromAddress.AddressLine1' => { required => 1, type => 'string' },
	'InboundShipmentHeader.ShipFromAddress.AddressLine2' => { type => 'string' },
	'InboundShipmentHeader.ShipFromAddress.City' => { required => 1, type => 'string' },
	'InboundShipmentHeader.ShipFromAddress.DistrictOrCounty' => { type => 'string' },
	'InboundShipmentHeader.ShipFromAddress.StateOrProvince' => { required => 1, type => 'string' },
	'InboundShipmentHeader.ShipFromAddress.PostalCode' => { required => 1, type => 'string' },
	'InboundShipmentHeader.ShipFromAddress.CountryCode' => { required => 1, type => 'string' },
	'InboundShipmentHeader.DestinationFulfillmentCenterId' => { required => 1, type => 'string' },
	'InboundShipmentHeader.ShipmentStatus' => { required => 1, type => 'string' },
	'InboundShipmentHeader.LabelPrepPreference' => { required => 1, type => 'string' },
        InboundShipmentItems => {
		   array_names => ['SellerSKU','QuantityShipped'],
	           type => 'memberArray',
        }
    };

