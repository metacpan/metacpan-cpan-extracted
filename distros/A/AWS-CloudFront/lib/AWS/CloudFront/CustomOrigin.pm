
package S3::CloudFront::CustomOrigin;

use VSO;
use Data::Validate::Domain 'is_domain';


has 'DNSName' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
  where     => sub {
    is_domain($_, { do_allow_underscore => 1 })
  }
);


has 'HTTPPort' => (
  is        => 'ro',
  isa       => 'Int',
  required  => 0,
  default   => sub { 80 },
  where     => sub {
    $_ == 80 ||
    $_ == 443 ||
    (
      $_ >= 1024 &&
      $_ <= 65535
    )
  }
);

has 'HTTPSPort' => (
  is        => 'ro',
  isa       => 'Int',
  required  => 0,
  default   => sub { 443 },
  where     => sub {
    $_ == 80 ||
    $_ == 443 ||
    (
      $_ >= 1024 &&
      $_ <= 65535
    )
  }
);

has 'OriginProtocolPolicy' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
  where     => sub {
    $_ =~ m{^(http-only|match-viewer)$}
  }
);

1;# return true:

