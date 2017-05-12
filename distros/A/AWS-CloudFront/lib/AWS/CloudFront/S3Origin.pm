
package AWS::CloudFront::S3Origin;

use VSO;

has 'DNSName' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'OriginAccessIdentity' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
);

1;# return true:

