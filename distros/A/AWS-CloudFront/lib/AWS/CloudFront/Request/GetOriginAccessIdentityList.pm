
package
AWS::CloudFront::Request::GetOriginAccessIdentityList;

use VSO;
use AWS::CloudFront::Signer;
use AWS::CloudFront::ResponseParser;

extends 'AWS::CloudFront::Request';

has 'Marker' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
);

has 'MaxItems' => (
  is        => 'ro',
  isa       => 'Int',
  required  => 0,
);


sub request
{
  my $s = shift;
  
  my $uri = 'https://cloudfront.amazonaws.com/2010-11-01/origin-access-identity/cloudfront';
  my @params = ( );
  push @params, 'Marker=' . $s->Marker if defined $s->Marker;
  push @params, 'MaxItems=' . $s->MaxItems if defined $s->MaxItems;
  $uri .= '?' . join('&', @params) if @params;
  
  my $signer = AWS::CloudFront::Signer->new(
    cf  => $s->cf,
  );
  $s->_send_request( 'GET' => $uri => {
    Authorization => $signer->auth_header,
    'x-amz-date'  => $signer->date,
  });
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

