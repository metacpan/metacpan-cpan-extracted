
package AWS::CloudFront::Logging;

use VSO;

subtype 'AWS::CloudFront::Logging::Prefix'
  => as       'Str'
  => where    { length($_) <= 256 && $_ !~ m{^/} && $_ =~ m{/$} }
  => message  { "length <= 256, can't start with '/' and must end with '/'" }

has 'Bucket' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'Prefix' => (
  is        => 'ro',
  isa       => 'Maybe[AWS::CloudFront::Logging::Prefix]',
);

1;# return true:

