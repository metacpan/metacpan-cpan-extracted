package Amazon::MWS::Sellers;

use Amazon::MWS::Routines qw(:all);

my $sellers_service = '/Sellers/2011-07-01';

define_api_method GetServiceStatus => 
    raw_body => 0,
    service => "$sellers_service",
    module_name => 'Amazon::MWS::Sellers',
    parameters => {},
    respond => sub {
	my $root = shift;
	return $root->{Status};
   };	

define_api_method ListMarketplaceParticipations =>
    raw_body => 1,
    service => "$sellers_service",
    parameters => {} ;	

define_api_method ListMarketplaceParticipationsByNextToken =>
    raw_body => 1,
    service => "$sellers_service",
    parameters => {
       NextToken => {
            type     => 'string',
            required => 1,
        },
    };
