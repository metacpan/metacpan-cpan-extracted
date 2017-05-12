use warnings;
use strict;

use Amazon::MWS::Client;
use Amazon::MWS::Enumeration::FeedType qw(:all);
use Amazon::MWS::Enumeration::FeedProcessingStatus qw(:all);
use Test::MockObject::Extends;
use Test::MockObject;
use HTTP::Response;
use Test::More tests => 4;
use DateTime;
use Data::Dumper;

my $client = Amazon::MWS::Client->new(
    access_key_id  => 'foo',
    secret_key     => 'bar',
    merchant_id    => 'baz',
    marketplace_id => 'goo',
);

my $agent = Test::MockObject->new->mock(
    request => sub {
        my $r = HTTP::Response->new(200);
        $r->content(<<'RESPONSE_XML');
<?xml version="1.0"?>
<SubmitFeedResponse xmlns="http://mws.amazonaws.com/doc/2009-01-01/"><SubmitFeedResult><FeedSubmissionInfo><FeedSubmissionId>11223344</FeedSubmissionId><FeedType>_POST_ORDER_FULFILLMENT_DATA_</FeedType><SubmittedDate>2011-02-08T09:49:35+00:00</SubmittedDate><FeedProcessingStatus>_SUBMITTED_</FeedProcessingStatus></FeedSubmissionInfo></SubmitFeedResult><ResponseMetadata><RequestId>11223344-effe-1122-a9a9-e1e111223344</RequestId></ResponseMetadata></SubmitFeedResponse>
RESPONSE_XML
        $r->content_type('text/xml; charset=utf-8');
        return $r;
    }
);

$client = Test::MockObject::Extends->new($client)->mock(
    agent => sub { $agent }
);

my $response;
eval {
$response = $client->SubmitFeed(
    content_type    => 'text/xml; charset=utf-8',
    FeedType        => _POST_ORDER_FULFILLMENT_DATA_,
    PurgeAndReplace => 0,
    FeedContent     => <<'FEED_CONTENT',
<?xml version="1.0" encoding="iso-8859-1"?>
<AmazonEnvelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="amzn-envelope.xsd">
  <Header>
    <DocumentVersion>1.01</DocumentVersion>
    <MerchantIdentifier>M_EXAMPLE_123456</MerchantIdentifier>
  </Header>
  <MessageType>Product</MessageType>
  <PurgeAndReplace>false</PurgeAndReplace>
  <Message>
    <MessageID>1</MessageID>
    <OperationType>Update</OperationType>
    <Product>
      <SKU>56789</SKU>
      <StandardProductID>
        <Type>ASIN</Type>
        <Value>B0EXAMPLEG</Value>
      </StandardProductID>
      <ProductTaxCode>A_GEN_NOTAX</ProductTaxCode>
      <DescriptionData>
        <Title>Example Product Title</Title>
        <Brand>Example Product Brand</Brand>
        <Description>This is an example product description.</Description>
        <BulletPoint>Example Bullet Point 1</BulletPoint>
        <BulletPoint>Example Bullet Point 2</BulletPoint>
        <MSRP currency="USD">25.19</MSRP>
        <Manufacturer>Example Product Manufacturer</Manufacturer>
        <ItemType>example-item-type</ItemType>
      </DescriptionData>
      <ProductData>
        <Health>
          <ProductType>
            <HealthMisc>
              <Ingredients>Example Ingredients</Ingredients>
              <Directions>Example Directions</Directions>
            </HealthMisc>
          </ProductType>
        </Health>
      </ProductData>
    </Product>
  </Message>
</AmazonEnvelope>
FEED_CONTENT
);
};

diag Dumper($@) if $@;

is $response->{FeedProcessingStatus}, _SUBMITTED_;
is $response->{FeedSubmissionId}, '11223344';
is $response->{FeedType}, _POST_ORDER_FULFILLMENT_DATA_;
is $response->{SubmittedDate}, DateTime->new(
    year => 2011,
    month => 2,
    day => 8,
    hour => 9,
    minute => 49,
    second => 35
);
