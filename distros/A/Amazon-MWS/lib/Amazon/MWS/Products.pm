package Amazon::MWS::Products;

use Amazon::MWS::Routines qw(:all);

my $version = '2011-10-01';
my $products_service = "/Products/$version";

define_api_method GetServiceStatus =>
    raw_body => 0,
    version => $version,
    service => "$products_service",
    parameters => {},
    respond => sub {
        my $root = shift;
        return $root->{Status};
   };

define_api_method ListMatchingProducts =>
    raw_body => 0,
    service => "$products_service",
    version => $version,
    parameters => {
        Query      => {
             type       => 'string',
             required   => 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
    },
    respond => sub {
        my $root = shift;
        # unclear if we can get an array here. TODO.
        return $root->{Products}->{Product};
    };

define_api_method GetMatchingProduct =>
    raw_body => 1,
    service => "$products_service",
    version => $version,
    parameters => {
        ASINList      => {
             type       => 'ASINList',
             required   => 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
    };

define_api_method GetMatchingProductForId =>
  raw_body => 0,
  service => $products_service,
  version => $version,
  parameters => {
                 MarketplaceId   => {
                                     type => 'string',
                                     required => 1
                                    },
                 IdType => {
                            type => 'string',
                            required => 1
                           },
                 IdList => {
                            type => 'IdList',
                            required =>  1,
                           }
                },
  respond => sub {
      my $root = shift;
      return unless $root; # failed totally
      if (ref($root) ne 'ARRAY') {
          return [ $root ];
      }
      else {
          return $root;
      }
  };

define_api_method GetMyFeesEstimate =>
  raw_body => 0,
  service => $products_service,
  version => $version,
  parameters => {
        'FeesEstimateRequestList' => {
                   required => 1,
                   array_names => ['MarketplaceId','IdType','IdValue','IsAmazonFulfilled','Identifier',
                      'PriceToEstimateFees.ListingPrice.Amount', 'PriceToEstimateFees.ListingPrice.CurrencyCode',
                      'PriceToEstimateFees.Shipping.Amount', 'PriceToEstimateFees.Shipping.CurrencyCode',
                      'PriceToEstimateFees.Points.PointsNumber'],
                   type => 'FeesEstimateRequestArray',

        },
        },
  respond => sub {
      my $root = shift;
      return unless $root; # failed totally
      if (ref($root) ne 'ARRAY') {
          return [ $root ];
      }
      else {
          return $root;
      }
  };

define_api_method GetLowestOfferListingsForSKU =>
    raw_body => 0,
    service => "$products_service",
    version => $version,
    parameters => {
        SellerSKUList      => {
             type       => 'SellerSKUList',
	     required	=> 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
        ItemCondition   => { type => 'List', values=>['Any', 'New', 'Used', 'Collectible', 'Refurbished', 'Club'],
                             required => 0 },
        ExcludeMe => { type => 'boolean' },
    },
    respond => \&_convert_lowest_offers_listing;

define_api_method GetLowestOfferListingsForASIN =>
    raw_body => 0,
    service => "$products_service",
    version => $version,
    parameters => {
        ASINList      => {
             type       => 'ASINList',
             required   => 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
        ItemCondition   => { type => 'List', values=>['Any', 'New', 'Used', 'Collectible', 'Refurbished', 'Club'],
                             required => 0  },
        ExcludeMe => { type => 'boolean' },
    },
    respond => \&_convert_lowest_offers_listing;


define_api_method GetCompetitivePricingForSKU =>
    raw_body => 1,
    service => "$products_service",
    version => $version,
    parameters => {
        SellerSKUList      => {
             type       => 'SellerSKUList',
	     required	=> 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
    };

define_api_method GetCompetitivePricingForASIN =>
    raw_body => 1,
    service => "$products_service",
    version => $version,
    parameters => {
        ASINList      => {
             type       => 'ASINList',
             required   => 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
    };

define_api_method GetLowestPricedOffersForSKU =>
    raw_body => 1,
    service => "$products_service",
    version => $version,
    parameters => {
        SellerSKU      => {
             type       => 'string',
	     required	=> 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
        ItemCondition   => { type => 'List', values=>['Any', 'New', 'Used', 'Collectible', 'Refurbished', 'Club'],
                             required => 1 },
    };

define_api_method GetLowestPricedOffersForASIN =>
    raw_body => 1,
    service => "$products_service",
    version => $version,
    parameters => {
        ASIN      => {
             type       => 'string',
             required   => 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
        ItemCondition   => { type => 'List', values=>['Any', 'New', 'Used', 'Collectible', 'Refurbished', 'Club'],
                             required => 1 },
    };

define_api_method GetMyPriceForSKU =>
    raw_body => 1,
    service => "$products_service",
    version => $version,
    parameters => {
        SellerSKUList      => {
             type       => 'SellerSKUList',
	     required	=> 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
        ItemCondition   => { type => 'List', values=>['Any', 'New', 'Used', 'Collectible', 'Refurbished', 'Club'],
                             required => 0 },
    };

define_api_method GetMyPriceForASIN =>
    raw_body => 1,
    service => "$products_service",
    version => $version,
    parameters => {
        ASINList      => {
             type       => 'ASINList',
             required   => 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
        ItemCondition   => { type => 'List', values=>['Any', 'New', 'Used', 'Collectible', 'Refurbished', 'Club'],
                             required => 0 },
    };

define_api_method GetProductCategoriesForSKU =>
    raw_body => 1,
    service => "$products_service",
    version => $version,
    parameters => {
        SellerSKU      => {
             type       => 'string',
	     required	=> 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
    };

define_api_method GetProductCategoriesForASIN =>
    raw_body => 0,
    service => "$products_service",
    version => $version,
    parameters => {
        ASIN      => {
             type       => 'string',
             required   => 1
        },
        MarketplaceId   => { type => 'string', required=>1 },
    },
    respond => sub {
        my $root = shift;
        force_array($root, 'Self');
        return $root->{Self};
    };

sub _convert_lowest_offers_listing {
    my $root = shift;
    return [] unless $root;
    # here basically we cut out the info we sent and get only the listings.
    if (my $listing = $root->{Product}->{LowestOfferListings}->{LowestOfferListing}) {
        if (ref($listing) ne 'ARRAY') {
            return [ $listing ];
        }
        else {
            return $listing;
        }
    }
    else {
        return [];
    }
}


1;

