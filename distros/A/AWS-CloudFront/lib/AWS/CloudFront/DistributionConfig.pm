
package AWS::CloudFront::DistributionConfig;

use VSO;
use Data::Validate::Domain 'is_domain';

has 'S3Origin' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront::S3Origin',
  required  => 0,
);

has 'CustomOrigin' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront::CustomOrigin',
  required  => 0,
);

has 'CallerReference' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'CNAME' => (
  is        => 'rw',
  isa       => 'Str',
  required  => 0,
  where     => sub {
    is_domain($_, {do_allow_underscore => 1})
  }
);

has 'Comment' => (
  is        => 'rw',
  isa       => 'Str',
  required  => 0,
);

has 'Enabled' => (
  is        => 'rw',
  isa       => 'Str',
  required  => 1,
  where     => sub {
    $_ =~ m{^(true|false)$}
  }
);

has 'DefaultRootObject' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
  where     => sub {
    (! defined $_) ||
    (! length $_) ||
    $_ =~ m{^([
      a-z
      A-Z
      0-9
      _\-\.\*\$\/\~"'\&
      |\&amp;
    ]+)$}x;
  }
);

has 'Logging' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront::Logging',
  required  => 0,
);

has 'TrustedSigners' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront::TrustedSigners',
  required  => 0,
);

has 'RequiredProtocols' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront::RequiredProtocols',
  required  => 0,
);

sub BUILD
{
  my $s = shift;
  
  die 'Must specify either an S3Origin or a CustomOrigin.'
    unless $s->S3Origin || $s->CustomOrigin;
  die 'You cannot use both S3Origin and CustomOrigin in the same distribution.'
    if $s->S3Origin && $s->CustomOrigin;
}# end BUILD()

1;# return true:

