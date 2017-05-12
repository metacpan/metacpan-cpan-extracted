package Amazon::MWS::FulfillmentInventory;

use Amazon::MWS::Routines qw(:all);

my $fulfillment_service = '/FulfillmentInventory/2010-10-01/';

define_api_method GetServiceStatus =>
    version => '2010-10-01',
    raw_body => 0,
    service => "$fulfillment_service",
    module_name => 'Amazon::MWS::FulfillmentInventory',
    parameters => {},
    respond => sub {
        my $root = shift;
        return $root->{Status};
   };

define_api_method ListInventorySupply =>
    raw_body => 1,
    version => '2010-10-01',
    service => "$fulfillment_service",
    parameters => {
        SellerSkus      => {
             type       => 'MemberList'
        },
        QueryStartDateTime      => { type => 'datetime' },
        ResponseGroup           => { type => 'List', values=>['Basic','Detailed'] }
    };

define_api_method ListInventorySupplyByNextToken =>
    raw_body => 1,
    version => '2010-10-01',
    service => "$fulfillment_service",
    parameters => {
        NextToken => {
            type     => 'string',
            required => 1,
        },
    };


1;
