
package
AWS::CloudFront::Request::DeleteDistribution;

use VSO;
use AWS::CloudFront::Signer;
use AWS::CloudFront::ResponseParser

extends 'AWS::CloudFront::Request';

has 'Id' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);


sub request
{
  my $s = shift;
  
  # First get the etag:
  my $etag = (sub{
    my $uri = 'https://cloudfront.amazonaws.com/2010-11-01/distribution/' . $s->Id;
    my $signer = AWS::CloudFront::Signer->new(
      cf  => $s->cf,
    );
    my $res = $s->_send_request( 'GET' => $uri => {
      Authorization => $signer->auth_header,
      'x-amz-date'  => $signer->date,
    });
    return $res->response->header('etag');
  })->();
  
  # Now we can delete the distribution:
  my $uri = 'https://cloudfront.amazonaws.com/2010-11-01/distribution/' . $s->Id;
  my $signer = AWS::CloudFront::Signer->new(
    cf  => $s->cf,
  );

  my $res = $s->_send_request( 'DELETE' => $uri => {
    Authorization => $signer->auth_header,
    'x-amz-date'  => $signer->date,
    'if-match'    => $etag,
  });
}# end request()

sub parse_response
{
  my ($s, $res) = @_;
  
  AWS::CloudFront::ResponseParser->new(
    response        => $res,
    expect_nothing  => 1,
    type            => $s->type,
  );
}# end http_request();

1;# return true:

