
package AWS::CloudFront::Distribution;

use VSO;
use AWS::CloudFront::OriginAccessIdentity;

has 'cf' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront',
  required  => 1,
);

has 'Id' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'Status'  => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
  where     => sub {
    m{^(?:Deployed|InProgress)$}
  }
);

has 'LastModifiedTime' => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  where     => sub {
    # eg: 2011-05-05T21:11:39.546Z
    m{^(?:\d\d\d\d-\d\d-\d\dT\d+:\d\d:\d\d\.\d+Z)$}
  }
);

has 'InProgressValidationBatches' => (
  is        => 'ro',
  isa       => 'Int',
  required  => 0,
  default   => sub { 0 }
);

has 'DomainName'  => (
  is        => 'rw',
  isa       => 'Str',
  required  => 1,
);

has 'ActiveTrustedSigners' => (
  is        => 'ro',
  isa       => 'ArrayRef[AWS::CloudFront::ActiveTrustedSigner]',
  required  => 0,
);

has 'Origin'  => (
  is        => 'ro',
  isa       => 'AWS::CloudFront::S3Origin|AWS::CloudFront::CustomOrigin',
  required  => 1,
);

has 'CallerReference' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
  lazy      => 1,
  default   => sub {
    my $s = shift;
    $s->cf->distribution( Id => $s->Id )->CallerReference
  },
);

has 'CNAME' => (
  is        => 'rw',
  isa       => 'Str',
  required  => 0,
);

has 'Comment' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
);

has 'Enabled' => (
  is        => 'rw',
  isa       => 'Bool',
  required  => 1,
);

has 'DefaultRootObject' => (
  is        => 'rw',
  isa       => 'Str',
  required  => 0,
);

has 'Logging' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront::Logging',
  required  => 0,
);

has 'TrustedSigners' => (
  is        => 'ro',
  isa       => 'ArrayRef[AWS::CloudFront::TrustedSigner]',
  required  => 0,
);

has 'OriginAccessIdentity' => (
  is        => 'ro',
  isa       => 'Maybe[AWS::CloudFront::OriginAccessIdentity]',
  required  => 0,
  lazy      => 1,
  default   => sub {
    my $s = shift;
    
    foreach my $ident ( $s->cf->origin_access_identities )
    {
    
    }# end foreach()
  }
);


sub update
{
  my $s = shift;
  
  my $type = 'UpdateDistribution';
  my $response = $s->cf->request( $type, Distribution => $s )->request();
  
  if( $response->error_code )
  {
    die $response->msg;
  }# end if()
}# end update()


sub delete
{
  my $s = shift;
  
  my $type = 'DeleteDistribution';
  my $response = $s->cf->request( $type, Id => $s->Id )->request();
  
  if( $response->error_code )
  {
    die $response->msg;
  }# end if()
}# end delete()


sub create_origin_access_identity
{
  my ($s, %args) = @_;
  
  my $type = 'CreateOriginAccessIdentity';
  my $response = $s->cf->request( $type,
    CallerReference => $s->CallerReference,
    Comment         => $args{Comment}
  )->request();
  
  if( $response->error_code )
  {
    die $response->msg;
  }# end if()
  
  my $xpc = $response->xpc;
  if( my ($node) = $xpc->findnodes('.//cf:CloudFrontOriginAccessIdentity') )
  {
    return AWS::CloudFront::OriginAccessIdentity->new(
      Id                => $xpc->findvalue('.//cf:Id', $node),
      S3CanonicalUserId => $xpc->findvalue('.//cf:S3CanonicalUserId', $node),
      CallerReference   => $xpc->findvalue('.//cf:CallerReference', $node),
      Location          => $response->response->header('Location'),
    );
  }
  elsif( my ($error) = $xpc->findnodes('.//cf:Error') )
  {
    if( my ($code) = $response->response->content =~ m{<Code>(.+?)</Code>}s )
    {
      # The origin already exists or some other error.
      die $code;
    }
    else
    {
      die "Invalid response: ", $response->response->content;
    }# end if()
  }
  else
  {
    die "Invalid response: ", $response->response->content;
  }# end if()
}# end create_origin_access_identity()

1;# return true:

