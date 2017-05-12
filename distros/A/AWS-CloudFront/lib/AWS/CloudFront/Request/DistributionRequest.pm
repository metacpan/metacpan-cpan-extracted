
package AWS::CloudFront::Request::DistributionRequest;

use VSO;

extends 'AWS::CloudFront::Request';


sub _uri
{
  my ( $s, $distribution_id ) = @_;
  
  return $distribution_id
    ? "/2010-11-01/distribution/$distribution_id"
    : "/2010-11-01/distribution";
}# end _uri()

1;# return true:

