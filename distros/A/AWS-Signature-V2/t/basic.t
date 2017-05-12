use strict;
use warnings;
use Test::More;

use AWS::Signature::V2;
use LWP::UserAgent;

# http://docs.amazonwebservices.com/AWSECommerceService/latest/DG/index.html

my $signer = AWS::Signature::V2->new(
    aws_access_key => '00000000000000000000',
    aws_secret_key => '1234567890',
);
my $uri = URI->new('https://webservices.amazon.com/onca/xml');
$uri->query_form(
    AWSAccessKeyId=>'00000000000000000000',
    ItemId=>'0679722769',
    Operation=>'ItemLookup',
    ResponseGroup=>"ItemAttributes,Offers,Images,Reviews",
    Service=>"AWSECommerceService",
    Timestamp=>"2009-01-01T12:00:00Z",
    Version=>'2009-01-06',
);
my $signed_uri = $signer->sign($uri);

is $signer->signature($signed_uri), 'Nace+U3Az4OhN7tISqgs1vdLBHBEijWcBeCqL5xN9xg=';

done_testing;
