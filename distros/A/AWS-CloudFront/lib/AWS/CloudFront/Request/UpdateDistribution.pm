
package
AWS::CloudFront::Request::UpdateDistribution;

use VSO;
use AWS::CloudFront::Signer;
use AWS::CloudFront::ResponseParser;

extends 'AWS::CloudFront::Request';

has 'Distribution' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront::Distribution',
  required  => 1,
);

sub d { shift->Distribution }


sub request
{
  my $s = shift;
  
  # First get the etag:
  my $etag = (sub{
    my $uri = 'https://cloudfront.amazonaws.com/2010-11-01/distribution/' . $s->d->Id;
    my $signer = AWS::CloudFront::Signer->new(
      cf  => $s->cf,
    );
    my $res = $s->_send_request( 'GET' => $uri => {
      Authorization => $signer->auth_header,
      'x-amz-date'  => $signer->date,
    });
    return $res->response->header('etag');
  })->();
  
  my $uri = 'https://cloudfront.amazonaws.com/2010-11-01/distribution/' . $s->d->Id . '/config';

  my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<DistributionConfig xmlns="http://cloudfront.amazonaws.com/doc/2010-11-01/">
  @{[ $s->_origin_xml ]}
  <CallerReference>@{[ $s->d->CallerReference ]}</CallerReference>
  @{[ $s->d->CNAME ? q(<CNAME>) . $s->d->CNAME . q(</CNAME>) : '' ]}
  <Comment>@{[ $s->d->Comment ]}</Comment>
  <Enabled>@{[ $s->d->Enabled ? 'true' : 'false' ]}</Enabled>
  @{[ $s->d->DefaultRootObject ? ('<DefaultRootObject>' . $s->d->efaultRootObject. '</DefaultRootObject>') : '' ]}
  @{[ $s->_logging_xml ]}
</DistributionConfig>
XML

  my $signer = AWS::CloudFront::Signer->new(
    cf  => $s->d->cf,
  );
  $s->_send_request( 'POST' => $uri => {
    Authorization => $signer->auth_header,
    'x-amz-date'  => $signer->date,
    'if-match'    => $etag,
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
  
  my $type = ref($s->d->Origin);
  if( $type->isa('AWS::CloudFront::S3Origin') )
  {
    return <<"XML";
   <S3Origin>
      <DNSName>@{[ $s->d->Origin->DNSName ]}</DNSName>
   </S3Origin>
XML
  }
  elsif( $type->isa('AWS::CloudFront::CustomOrigin') )
  {
    return <<"XML";
   <CustomOrigin>
      <DNSName>@{[ $s->d->Origin->DNSName ]}</DNSName>
      <HTTPPort>@{[ $s->d->Origin->HTTPPort ]}</HTTPPort>
      <OriginProtocolPolicy>@{[ $s->Origin->OriginProtocolPolicy ]}</OriginProtocolPolicy>
   </CustomOrigin>
XML
  }# end if()
}# end _origin_xml()


sub _logging_xml
{
  my $s = shift;
  return '' unless $s->d->Logging;
  
  return <<"XML";
   <Logging>
      <Bucket>@{[ $s->d->Logging->Bucket ]}.s3.amazonaws.com</Bucket>
      <Prefix>@{[ $s->d->Logging->Prefix ]}</Prefix>
   </Logging>
XML
}# end _logging_xml()

1;# return true:

