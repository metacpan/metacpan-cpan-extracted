
package
AWS::CloudFront::Request::CreateOriginAccessIdentity;

use VSO;
use AWS::CloudFront::Signer;
use AWS::CloudFront::ResponseParser;

extends 'AWS::CloudFront::Request';

has 'CallerReference' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'Comment' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
  default   => sub { '' },
);


sub request
{
  my $s = shift;
  
  my $uri = 'https://cloudfront.amazonaws.com/2010-11-01/origin-access-identity/cloudfront';

  my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<CloudFrontOriginAccessIdentityConfig xmlns="http://cloudfront.amazonaws.com/doc/2010-11-01/">
   <CallerReference>@{[ $s->CallerReference ]}</CallerReference>
   <Comment>@{[ $s->Comment ]}</Comment>
</CloudFrontOriginAccessIdentityConfig>
XML

  my $signer = AWS::CloudFront::Signer->new(
    cf  => $s->cf,
  );
  $s->_send_request( 'POST' => $uri => {
    Authorization => $signer->auth_header,
    'x-amz-date'  => $signer->date,
  }, $xml);
}# end request()

sub parse_response
{
  my ($s, $res) = @_;
  
  AWS::CloudFront::ResponseParser->new(
    response        => $res,
    expect_nothing  => 0,
    type            => $s->type,
  );
}# end http_request()

1;# return true:

