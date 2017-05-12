#!perl

use strict;
use warnings;
use Amazon::MWS::XML::Response::FeedSubmissionResult;
use Data::Dumper;
use File::Spec;
use Test::More;
use XML::Compile::Schema;

if (-d 'schemas') {
    plan tests => 42;
}
else {
    plan skip_all => q{Missing "schemas" directory with the xsd from Amazon, skipping feeds tests};
}


my $reader = XML::Compile::Schema->new([glob File::Spec->catfile('schemas',
                                                                 '*.xsd')])
  ->compile(READER => 'AmazonEnvelope');


my $xml = <<'XML';
<AmazonEnvelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="amzn-envelope.xsd">
        <Header>
                <DocumentVersion>1.02</DocumentVersion>
                <MerchantIdentifier>_MERCHANT_ID_</MerchantIdentifier>
        </Header>
        <MessageType>ProcessingReport</MessageType>
        <Message>
                <MessageID>1</MessageID>
                <ProcessingReport>
                        <DocumentTransactionID>123412341234</DocumentTransactionID>
                        <StatusCode>Complete</StatusCode>
                        <ProcessingSummary>
                                <MessagesProcessed>7</MessagesProcessed>
                                <MessagesSuccessful>1</MessagesSuccessful>
                                <MessagesWithError>6</MessagesWithError>
                                <MessagesWithWarning>0</MessagesWithWarning>
                        </ProcessingSummary>
                        <Result>
                                <MessageID>1</MessageID>
                                <ResultCode>Error</ResultCode>
                                <ResultMessageCode>6024</ResultMessageCode>
                                <ResultDescription>Seller is not authorized to list products by this brand name in this product line or category. For more details, see http://sellercentral.amazon.de/gp/errorcode/6024</ResultDescription>
                                <AdditionalInfo>
                                        <SKU>16414</SKU>
                                </AdditionalInfo>
                        </Result>
                        <Result>
                                <MessageID>2</MessageID>
                                <ResultCode>Error</ResultCode>
                                <ResultMessageCode>6025</ResultMessageCode>
                                <ResultDescription>Seller is not authorized to list products by this brand name in this product line or category. For more details, see http://sellercentral.amazon.de/gp/errorcode/6024</ResultDescription>
                                <AdditionalInfo>
                                        <SKU>12110</SKU>
                                </AdditionalInfo>
                        </Result>
                        <Result>
                                <MessageID>3</MessageID>
                                <ResultCode>Error</ResultCode>
                                <ResultMessageCode>6026</ResultMessageCode>
                                <ResultDescription>Seller is not authorized to list products by this brand name in this product line or category. For more details, see http://sellercentral.amazon.de/gp/errorcode/6024</ResultDescription>
                                <AdditionalInfo>
                                        <SKU>12112</SKU>
                                </AdditionalInfo>
                        </Result>
                        <Result>
                                <MessageID>4</MessageID>
                                <ResultCode>Error</ResultCode>
                                <ResultMessageCode>6024</ResultMessageCode>
                                <ResultDescription>Seller is not authorized to list products by this brand name in this product line or category. For more details, see http://sellercentral.amazon.de/gp/errorcode/6024</ResultDescription>
                                <AdditionalInfo>
                                        <SKU>14742</SKU>
                                </AdditionalInfo>
                        </Result>
                        <Result>
                                <MessageID>6</MessageID>
                                <ResultCode>Error</ResultCode>
                                <ResultMessageCode>6024</ResultMessageCode>
                                <ResultDescription>Seller is not authorized to list products by this brand name in this product line or category. For more details, see http://sellercentral.amazon.de/gp/errorcode/6024</ResultDescription>
                                <AdditionalInfo>
                                        <SKU>12194</SKU>
                                </AdditionalInfo>
                        </Result>
                        <Result>
                                <MessageID>7</MessageID>
                                <ResultCode>Error</ResultCode>
                                <ResultMessageCode>6024</ResultMessageCode>
                                <ResultDescription>Seller is not authorized to list products by this brand name in this product line or category. For more details, see http://sellercentral.amazon.de/gp/errorcode/6024</ResultDescription>
                                <AdditionalInfo>
                                        <SKU>16415</SKU>
                                </AdditionalInfo>
                        </Result>
                </ProcessingReport>
        </Message>
</AmazonEnvelope> 
XML

my $result = Amazon::MWS::XML::Response::FeedSubmissionResult->new(xml => $xml,
                                                                   xml_reader => $reader,
                                                                  );

ok($result);
ok(!$result->is_success);
ok($result->errors) and diag $result->errors;
ok(!$result->warnings, "No warnings");

ok(!$result->skus_warnings, "No warnings structure")
  or diag Dumper($result->skus_warnings);
ok($result->skus_errors, "Error structure found");

is_deeply([ $result->skus_with_warnings ], []);
is_deeply([ $result->failed_skus ], [qw/16414 12110 12112 14742 12194 16415/]);

my @errors = $result->report_errors;

foreach my $err (@errors) {
    foreach my $k (qw/code message type/) {
        ok ($err->{$k}, "Found $k $err->{$k} in error");
    }
}


$xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<AmazonEnvelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="amzn-envelope.xsd">
	<Header>
		<DocumentVersion>1.02</DocumentVersion>
		<MerchantIdentifier>_MERCHANT_ID_</MerchantIdentifier>
	</Header>
	<MessageType>ProcessingReport</MessageType>
	<Message>
		<MessageID>1</MessageID>
		<ProcessingReport>
			<DocumentTransactionID>12341234</DocumentTransactionID>
			<StatusCode>Complete</StatusCode>
			<ProcessingSummary>
				<MessagesProcessed>1</MessagesProcessed>
				<MessagesSuccessful>1</MessagesSuccessful>
				<MessagesWithError>0</MessagesWithError>
				<MessagesWithWarning>1</MessagesWithWarning>
			</ProcessingSummary>
			<Result>
				<MessageID>1</MessageID>
				<ResultCode>Warning</ResultCode>
				<ResultMessageCode>5000</ResultMessageCode>
				<ResultDescription>The update for Sku &apos;16446&apos; was skipped because it is identical to the update in feed &apos;xxxxx&apos;.</ResultDescription>
				<AdditionalInfo>
					<SKU>16446</SKU>
				</AdditionalInfo>
			</Result>
		</ProcessingReport>
	</Message>
</AmazonEnvelope>
XML

$result = Amazon::MWS::XML::Response::FeedSubmissionResult->new(xml => $xml,
                                                                xml_reader => $reader);

ok($result);
ok($result->is_success, "Is success even with warnings");
ok(!$result->errors, "No errors");
ok($result->warnings, "Has warnings") and diag $result->warnings;
ok($result->skus_warnings); #  and diag Dumper($result->skus_warnings);
ok(!$result->skus_errors); #  and diag Dumper($result->skus_warnings);
is_deeply([ $result->failed_skus ], []);
is_deeply([ $result->skus_with_warnings ], [ qw/16446/ ]);


$xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<AmazonEnvelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="amzn-envelope.xsd">
        <Header>
                <DocumentVersion>1.02</DocumentVersion>
                <MerchantIdentifier>__MERCHANT__ID_</MerchantIdentifier>
        </Header>
        <MessageType>ProcessingReport</MessageType>
        <Message>
                <MessageID>1</MessageID>
                <ProcessingReport>
                        <DocumentTransactionID>12341234</DocumentTransactionID>
                        <StatusCode>Complete</StatusCode>
                        <ProcessingSummary>
                                <MessagesProcessed>1</MessagesProcessed>
                                <MessagesSuccessful>0</MessagesSuccessful>
                                <MessagesWithError>1</MessagesWithError>
                                <MessagesWithWarning>0</MessagesWithWarning>
                        </ProcessingSummary>
                        <Result>
                                <MessageID>1</MessageID>
                                <ResultCode>Error</ResultCode>
                                <ResultMessageCode>18028</ResultMessageCode>
                                <ResultDescription>Your order cannot be found using Merchant ID __MERCHANT__ID_ and Merchant Order 8888888. Enter the correct order ID and then resubmit your feed.</ResultDescription>
                        </Result>
                </ProcessingReport>
        </Message>
</AmazonEnvelope>
XML

$result = Amazon::MWS::XML::Response::FeedSubmissionResult
  ->new(xml => $xml,
        xml_reader => $reader);

ok($result, "Result loaded");
ok(!$result->is_success, "Is not a success");
ok($result->errors, "Got the error " . $result->errors) or diag Dumper($result);
ok(!$result->warnings, "No warnings");



$xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<AmazonEnvelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="amzn-envelope.xsd">
        <Header>
                <DocumentVersion>1.02</DocumentVersion>
                <MerchantIdentifier>__MERCHANT_ID__</MerchantIdentifier>
        </Header>
        <MessageType>ProcessingReport</MessageType>
        <Message>
                <MessageID>1</MessageID>
                <ProcessingReport>
                        <DocumentTransactionID>123412341234</DocumentTransactionID>
                        <StatusCode>Complete</StatusCode>
                        <ProcessingSummary>
                                <MessagesProcessed>4</MessagesProcessed>
                                <MessagesSuccessful>1</MessagesSuccessful>
                                <MessagesWithError>3</MessagesWithError>
                                <MessagesWithWarning>0</MessagesWithWarning>
                        </ProcessingSummary>
                        <Result>
                                <MessageID>1</MessageID>
                                <ResultCode>Error</ResultCode>
                                <ResultMessageCode>18028</ResultMessageCode>
                                <ResultDescription>The data you submitted is incomplete or invalid. For help fixing this, see http://sellercentral-europe.amazon.com/gp/help/30721</ResultDescription>
                                <AdditionalInfo>
                                        <AmazonOrderID>302-6666666-6666666</AmazonOrderID>
                                </AdditionalInfo>
                        </Result>
                        <Result>
                                <MessageID>2</MessageID>
                                <ResultCode>Error</ResultCode>
                                <ResultMessageCode>18028</ResultMessageCode>
                                <ResultDescription>The data you submitted is incomplete or invalid. For help fixing this, see http://sellercentral-europe.amazon.com/gp/help/30721</ResultDescription>
                                <AdditionalInfo>
                                        <AmazonOrderID>302-5555555-5555555</AmazonOrderID>
                                </AdditionalInfo>
                        </Result>
                        <Result>
                                <MessageID>4</MessageID>
                                <ResultCode>Error</ResultCode>
                                <ResultMessageCode>18028</ResultMessageCode>
                                <ResultDescription>The data you submitted is incomplete or invalid. For help fixing this, see http://sellercentral-europe.amazon.com/gp/help/30721</ResultDescription>
                                <AdditionalInfo>
                                        <AmazonOrderID>305-4444444-4444444</AmazonOrderID>
                                </AdditionalInfo>
                        </Result>
                </ProcessingReport>
        </Message>
</AmazonEnvelope>
XML

$result = Amazon::MWS::XML::Response::FeedSubmissionResult
  ->new(xml => $xml,
        xml_reader => $reader);


ok($result, "object ok");

ok(!$result->orders_warnings, "No warnings");
is_deeply($result->orders_errors,
          [
           {
            'error' => 'The data you submitted is incomplete or invalid. For help fixing this, see http://sellercentral-europe.amazon.com/gp/help/30721',
            'order_id' => '302-6666666-6666666',
            'code' => '18028'
           },
           {
            'error' => 'The data you submitted is incomplete or invalid. For help fixing this, see http://sellercentral-europe.amazon.com/gp/help/30721',
            'order_id' => '302-5555555-5555555',
            'code' => '18028'
           },
           {
            'error' => 'The data you submitted is incomplete or invalid. For help fixing this, see http://sellercentral-europe.amazon.com/gp/help/30721',
            'order_id' => '305-4444444-4444444',
            'code' => '18028'
           }
          ]);

is_deeply([$result->failed_orders], ['302-6666666-6666666',
                                     '302-5555555-5555555',
                                     '305-4444444-4444444' ]);
