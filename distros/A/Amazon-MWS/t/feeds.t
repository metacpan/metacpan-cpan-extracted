#!perl

use strict;
use warnings;
use utf8;
use Amazon::MWS::XML::Product;
use Amazon::MWS::XML::Feed;
use XML::Compile::Schema;
use File::Spec;
use Test::More;

# testing requires a directory with the schema

if (-d 'schemas') {
    plan tests => 51;
}
else {
    plan skip_all => q{Missing "schemas" directory with the xsd from Amazon, skipping feeds tests};
}

my $writer = XML::Compile::Schema->new([glob File::Spec->catfile('schemas',
                                                                 '*.xsd')])
  ->compile(WRITER => 'AmazonEnvelope');


my @products;
foreach my $product ({
                      sku => '1234',
                      ean => '1234123412343',
                      brand => 'blabla',
                      title => 'title',
                      price => '10.00',
                      description => 'my desc',
                      images => [ 'http://example.org/pippo.jpg' ],
                      category_code => '111111',
                      product_data => { CE => { ProductType  => { PhoneAccessory => {} } } },
                      manufacturer => 'A manufacturer',
                      manufacturer_part_number => '1234123412343',
                      condition => 'Refurbished',
                      condition_note => 'Looks like new',
                      inventory => 1,
                      search_terms => [qw/a b c d e f g/],
                      features => [qw/f1 f2 f3/, '',  qw/f4 f5 f6 f7/],
                      shipping_weight => '5',
                      shipping_weight_unit => 'GR',
                      package_weight => 290,
                     },
                     {
                      sku => '3333',
                      ean => '4444123412343',
                      brand => 'brand',
                      title => 'title2',
                      price => '12.00',
                      description => 'my desc 2',
                      images => [ 'http://example.org/pluto.jpg' ],
                      category_code => '111111',
                      product_data => { Sports => { ProductType => 'SportingGoods' } },
                      manufacturer_part_number => '4444123412343',
                      inventory => 2,
                      shipping_weight => 0,
                      package_weight => 0,
                     }) {
    push @products, Amazon::MWS::XML::Product->new(%$product);
}


my $feeder = Amazon::MWS::XML::Feed->new(
                                         products => \@products,
                                         xml_writer => $writer,
                                         merchant_id => '__MERCHANT_ID__',
                                        );

my $exp_product_feed = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<AmazonEnvelope>
  <Header>
    <DocumentVersion>1.1</DocumentVersion>
    <MerchantIdentifier>__MERCHANT_ID__</MerchantIdentifier>
  </Header>
  <MessageType>Product</MessageType>
  <Message>
    <MessageID>1</MessageID>
    <OperationType>Update</OperationType>
    <Product>
      <SKU>1234</SKU>
      <StandardProductID>
        <Type>EAN</Type>
        <Value>1234123412343</Value>
      </StandardProductID>
      <Condition>
        <ConditionType>Refurbished</ConditionType>
        <ConditionNote>Looks like new</ConditionNote>
      </Condition>
      <DescriptionData>
        <Title>title</Title>
        <Brand>blabla</Brand>
        <Description>my desc</Description>
        <BulletPoint>f1</BulletPoint>
        <BulletPoint>f2</BulletPoint>
        <BulletPoint>f3</BulletPoint>
        <BulletPoint>f4</BulletPoint>
        <BulletPoint>f5</BulletPoint>
        <PackageWeight unitOfMeasure="GR">290</PackageWeight>
        <ShippingWeight unitOfMeasure="GR">5</ShippingWeight>
        <Manufacturer>A manufacturer</Manufacturer>
        <MfrPartNumber>1234123412343</MfrPartNumber>
        <SearchTerms>a</SearchTerms>
        <SearchTerms>b</SearchTerms>
        <SearchTerms>c</SearchTerms>
        <SearchTerms>d</SearchTerms>
        <SearchTerms>e</SearchTerms>
        <RecommendedBrowseNode>111111</RecommendedBrowseNode>
      </DescriptionData>
      <ProductData>
        <CE>
          <ProductType>
            <PhoneAccessory/>
          </ProductType>
        </CE>
      </ProductData>
    </Product>
  </Message>
  <Message>
    <MessageID>2</MessageID>
    <OperationType>Update</OperationType>
    <Product>
      <SKU>3333</SKU>
      <StandardProductID>
        <Type>EAN</Type>
        <Value>4444123412343</Value>
      </StandardProductID>
      <Condition>
        <ConditionType>New</ConditionType>
      </Condition>
      <DescriptionData>
        <Title>title2</Title>
        <Brand>brand</Brand>
        <Description>my desc 2</Description>
        <MfrPartNumber>4444123412343</MfrPartNumber>
        <RecommendedBrowseNode>111111</RecommendedBrowseNode>
      </DescriptionData>
      <ProductData>
        <Sports>
          <ProductType>SportingGoods</ProductType>
        </Sports>
      </ProductData>
    </Product>
  </Message>
</AmazonEnvelope>
XML

my $exp_inventory_feed = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<AmazonEnvelope>
  <Header>
    <DocumentVersion>1.1</DocumentVersion>
    <MerchantIdentifier>__MERCHANT_ID__</MerchantIdentifier>
  </Header>
  <MessageType>Inventory</MessageType>
  <Message>
    <MessageID>1</MessageID>
    <OperationType>Update</OperationType>
    <Inventory>
      <SKU>1234</SKU>
      <Quantity>1</Quantity>
      <FulfillmentLatency>2</FulfillmentLatency>
    </Inventory>
  </Message>
  <Message>
    <MessageID>2</MessageID>
    <OperationType>Update</OperationType>
    <Inventory>
      <SKU>3333</SKU>
      <Quantity>2</Quantity>
      <FulfillmentLatency>2</FulfillmentLatency>
    </Inventory>
  </Message>
</AmazonEnvelope>
XML

my $exp_price_feed = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<AmazonEnvelope>
  <Header>
    <DocumentVersion>1.1</DocumentVersion>
    <MerchantIdentifier>__MERCHANT_ID__</MerchantIdentifier>
  </Header>
  <MessageType>Price</MessageType>
  <Message>
    <MessageID>1</MessageID>
    <OperationType>Update</OperationType>
    <Price>
      <SKU>1234</SKU>
      <StandardPrice currency="EUR">10.00</StandardPrice>
    </Price>
  </Message>
  <Message>
    <MessageID>2</MessageID>
    <OperationType>Update</OperationType>
    <Price>
      <SKU>3333</SKU>
      <StandardPrice currency="EUR">12.00</StandardPrice>
    </Price>
  </Message>
</AmazonEnvelope>
XML

my $exp_image_feed = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<AmazonEnvelope>
  <Header>
    <DocumentVersion>1.1</DocumentVersion>
    <MerchantIdentifier>__MERCHANT_ID__</MerchantIdentifier>
  </Header>
  <MessageType>ProductImage</MessageType>
  <Message>
    <MessageID>1</MessageID>
    <OperationType>Update</OperationType>
    <ProductImage>
      <SKU>1234</SKU>
      <ImageType>Main</ImageType>
      <ImageLocation>http://example.org/pippo.jpg</ImageLocation>
    </ProductImage>
  </Message>
  <Message>
    <MessageID>2</MessageID>
    <OperationType>Update</OperationType>
    <ProductImage>
      <SKU>3333</SKU>
      <ImageType>Main</ImageType>
      <ImageLocation>http://example.org/pluto.jpg</ImageLocation>
    </ProductImage>
  </Message>
</AmazonEnvelope>
XML

my $exp_variants_feed;

is ($feeder->product_feed, $exp_product_feed, "product feed ok");
is ($feeder->inventory_feed, $exp_inventory_feed, "inventory feed ok");
is ($feeder->price_feed, $exp_price_feed, "price feed ok");
is ($feeder->image_feed, $exp_image_feed, "image feed ok");
is ($feeder->variants_feed, $exp_variants_feed, "variants feed ok (undef)");




my $test = Amazon::MWS::XML::Product->new(sku => '12345',
                                          price => '10',
                                          ean => '4444123412343',
                                          condition => 'UsedAcceptable');

is $test->condition, 'UsedAcceptable';
is $test->condition_type_for_lowest_price_listing, 'Used';

my %testconstructor = (
                                              sku => '3333',
                                              ean => '4444123412343',
                                              brand => 'brand',
                                              title => 'title2',
                                              price => '12.00',
                                              description => 'my desc 2',
                                              images => [ 'http://example.org/pluto.jpg' ],
                                              category_code => '111111',
                                              category => 'CE',
                                              subcategory => 'PhoneAccessory',
                                              manufacturer_part_number => '4444123412343',
                                              inventory => 2,
                                              manufacturer => '',
                      );


$testconstructor{condition} = 'blablabla';

eval { $test = Amazon::MWS::XML::Product->new(%testconstructor); };

like $@, qr/condition/, "Found exception for garbage in condition";

delete $testconstructor{condition};
$testconstructor{manufacturer} = 'abc' x 50;

eval { $test = Amazon::MWS::XML::Product->new(%testconstructor); };

like $@, qr/Max characters is 50/, "Found exception when manufacturer is too long";

delete $testconstructor{manufacturer};

$testconstructor{ean} = '1'x 7;
eval { $test = Amazon::MWS::XML::Product->new(%testconstructor) };
like $@, qr/Min characters is 8/, "Found exception when ean is not long enough";


$testconstructor{ean} = '1' x 17;
eval { $test = Amazon::MWS::XML::Product->new(%testconstructor) };
like $@, qr/Max characters is 16/, "Found exception when ean is not long enough";

$testconstructor{ean} = '1' x 8;
eval { $test = Amazon::MWS::XML::Product->new(%testconstructor) };
ok (!$@, "No exception");

$testconstructor{ean} = '1' x 16;
eval { $test = Amazon::MWS::XML::Product->new(%testconstructor) };
ok (!$@, "No exception");


$testconstructor{ean} = '4444123412343';
eval { $test = Amazon::MWS::XML::Product->new(%testconstructor) };
ok (!$@, "No exception");

$feeder = Amazon::MWS::XML::Feed->new(products => [ $test ],
                                      xml_writer => $writer,
                                      merchant_id => '__MERCHANT_ID__',
                                      );
unlike($feeder->product_feed, qr/<Manufacturer>/,
       "No manufacturer found in the feed");
diag $feeder->product_feed;

$test = Amazon::MWS::XML::Product->new(sku => '12345',
                                       price => '10',
                                       ean => '4444123412343',
                                       condition => 'UsedAcceptable');

ok(!$test->price_is_zero);

eval {
    $test = Amazon::MWS::XML::Product->new(sku => '12345',
                                           price => '-10',
                                           ean => '4444123412343',
                                           condition => 'UsedAcceptable');
};
like $@, qr/is negative/, "Exception with negative price: $@";

$test = Amazon::MWS::XML::Product->new(sku => '12345',
                                       price => '0.000000',
                                       ean => '4444123412343',
                                       inventory => 10,
                                       images => ['a.jpg'],
                                       children => ['123414-XXL'],
                                       condition => 'New');

ok($test->price_is_zero);
ok($test->is_inactive);
is($test->as_price_hash, undef, "zero priced item gets no price feed");
is($test->inventory, 10);
is($test->as_inventory_hash->{Quantity}, 0,
   "zero priced items get an inventory of 0");
is($test->as_images_array, undef, "zero priced items gets no image feed");
is($test->as_variants_hash, undef, "zero priced items gets no variant feed");

$feeder = Amazon::MWS::XML::Feed->new(products => [ $test ],
                                      xml_writer => $writer,
                                      merchant_id => '__MERCHANT_ID__',
                                      );

like($feeder->product_feed, qr/SKU>12345</, "Product feed found");
like($feeder->inventory_feed, qr/Quantity>0</, "Quantity found");
ok(!$feeder->price_feed, "No price feed");
ok(!$feeder->image_feed, "No image feed");
ok(!$feeder->variants_feed, "No variant feed");


$test = Amazon::MWS::XML::Product->new(sku => '12345',
                                       price => '100',
                                       ean => '4444123412343',
                                       inventory => -1,
                                       images => ['a.jpg'],
                                       children => ['123414-XXL'],
                                       condition => 'New');

ok(!$test->price_is_zero);
ok($test->is_inactive);
is($test->as_price_hash, undef, "inactive items get no price feed");
is($test->inventory, -1);
is($test->as_inventory_hash->{Quantity}, 0,
   "inactive items get an inventory of 0");
is($test->as_images_array, undef, "inactive items gets no image feed");
is($test->as_variants_hash, undef, "inactive items gets no variant feed");

$feeder = Amazon::MWS::XML::Feed->new(products => [ $test ],
                                      xml_writer => $writer,
                                      merchant_id => '__MERCHANT_ID__',
                                      );

like($feeder->product_feed, qr/SKU>12345</, "Product feed found");
like($feeder->inventory_feed, qr/Quantity>0</, "Quantity found");
ok(!$feeder->price_feed, "No price feed");
ok(!$feeder->image_feed, "No image feed");
ok(!$feeder->variants_feed, "No variant feed");

$test->feeds_needed([]);
$feeder = Amazon::MWS::XML::Feed->new(products => [ $test ],
                                      xml_writer => $writer,
                                      merchant_id => '__MERCHANT_ID__',
                                      );

ok(!$feeder->product_feed, "No product feed found");
ok(!$feeder->inventory_feed, "No quantity found");
ok(!$feeder->price_feed, "No price feed");
ok(!$feeder->image_feed, "No image feed");
ok(!$feeder->variants_feed, "No variant feed");

$test->feeds_needed([qw/inventory/]);
$feeder = Amazon::MWS::XML::Feed->new(products => [ $test ],
                                      xml_writer => $writer,
                                      merchant_id => '__MERCHANT_ID__',
                                      );

ok(!$feeder->product_feed, "No product feed found");
ok($feeder->inventory_feed, "Inventory found");
ok(!$feeder->price_feed, "No price feed");
ok(!$feeder->image_feed, "No image feed");
ok(!$feeder->variants_feed, "No variant feed");

