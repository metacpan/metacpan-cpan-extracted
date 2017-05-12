
package
AWS::CloudFront::Request::CreateDistribution;

use VSO;
use AWS::CloudFront::Signer;
use AWS::CloudFront::ResponseParser;
use Time::HiRes 'gettimeofday';

extends 'AWS::CloudFront::Request';

has 'Origin' => (
  is          => 'ro',
  isa         => 'AWS::CloudFront::S3Origin|AWS::CloudFront::CustomOrigin',
  required    => 1,
);

has 'CallerReference' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
  lazy      => 1,
  default   => sub { gettimeofday() },
);

has 'Logging' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront::Logging',
  required  => 0,
);

has 'CNAME' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
);

has 'Comment' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
  default   => sub { '' }
);

has 'Enabled' => (
  is        => 'ro',
  isa       => 'Bool',
  required  => 0,
  default   => sub { 1 },
);

has 'DefaultRootObject' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
);


sub request
{
  my $s = shift;
  
  my $uri = 'https://cloudfront.amazonaws.com/2010-11-01/distribution';

  my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<DistributionConfig xmlns="http://cloudfront.amazonaws.com/doc/2010-11-01/">
  @{[ $s->_origin_xml ]}
  <CallerReference>@{[ $s->CallerReference ]}</CallerReference>
  @{[ $s->CNAME ? q(<CNAME>) . $s->CNAME . q(</CNAME>) : '' ]}
  <Comment>@{[ $s->Comment ]}</Comment>
  <Enabled>@{[ $s->Enabled ? 'true' : 'false' ]}</Enabled>
  @{[ $s->DefaultRootObject ? ('<DefaultRootObject>' . $s->DefaultRootObject. '</DefaultRootObject>') : '' ]}
  @{[ $s->_logging_xml ]}
</DistributionConfig>
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


sub _origin_xml
{
  my $s = shift;
  
  my $type = ref($s->Origin);
  if( $type->isa('AWS::CloudFront::S3Origin') )
  {
    return <<"XML";
   <S3Origin>
      <DNSName>@{[ $s->Origin->DNSName ]}</DNSName>
   </S3Origin>
XML
  }
  elsif( $type->isa('AWS::CloudFront::CustomOrigin') )
  {
    return <<"XML";
   <CustomOrigin>
      <DNSName>@{[ $s->Origin->DNSName ]}</DNSName>
      <HTTPPort>@{[ $s->Origin->HTTPPort ]}</HTTPPort>
      <OriginProtocolPolicy>@{[ $s->Origin->OriginProtocolPolicy ]}</OriginProtocolPolicy>
   </CustomOrigin>
XML
  }# end if()
}# end _origin_xml()


sub _logging_xml
{
  my $s = shift;
  return '' unless $s->Logging;
  
  return <<"XML";
   <Logging>
      <Bucket>@{[ $s->Logging->Bucket ]}.s3.amazonaws.com</Bucket>
      <Prefix>@{[ $s->Logging->Prefix ]}</Prefix>
   </Logging>
XML
}# end _logging_xml()

1;# return true:

