
package
AWS::CloudFront::OriginAccessIdentity;

use VSO;

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

has 'Location' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
);

has 'Id' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'S3CanonicalUserId' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

1;# return true:

