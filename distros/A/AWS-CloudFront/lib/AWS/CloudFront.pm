
package AWS::CloudFront;

use VSO;
use LWP::UserAgent;
use Carp 'confess';
use HTTP::Response;
use IO::Socket::INET;
use Class::Load 'load_class';

use AWS::CloudFront::Distribution;
use AWS::CloudFront::S3Origin;
use AWS::CloudFront::CustomOrigin;
use AWS::CloudFront::OriginAccessIdentity;

our $VERSION = '0.003';

has 'access_key_id' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'secret_access_key' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'ua' => (
  is        => 'ro',
  isa       => 'LWP::UserAgent',
  lazy      => 1,
  required  => 0,
  default => sub { LWP::UserAgent->new( agent => 'foo/bar v1.2' ) }
);


sub request
{
  my ($s, $type, %args) = @_;
  
  my $class = "AWS::CloudFront::Request::$type";
  load_class($class);
  return $class->new( %args, cf => $s, type => $type );
}# end request()


sub distribution
{
  my ($s, %args) = @_;
  
  my $type = 'GetDistribution';
  my $response = $s->request( $type, %args )->request();
  my $xpc = $response->xpc;
  
  if( my ($node) = $xpc->findnodes('.//cf:Distribution') )
  {
    my $origin;
    if( my ($origin_s3) = $xpc->findnodes('.//cf:S3Origin', $node) )
    {
      $origin = AWS::CloudFront::S3Origin->new(
        OriginAccessIdentity  => $xpc->findvalue('.//cf:OriginAccessIdentity', $origin_s3),
        DNSName               => $xpc->findvalue('.//cf:DNSName', $origin_s3),
      );
    }
    elsif( my $origin_custom = $xpc->findnode('.//cf:CustomOrigin', $node) )
    {
    
    }# end if()
    my $dist = AWS::CloudFront::Distribution->new(
      cf                          => $s,
      Id                          => $xpc->findvalue('.//cf:Id', $node),
      Status                      => $xpc->findvalue('.//cf:Status', $node),
      LastModifiedTime            => $xpc->findvalue('.//cf:LastModifiedTime', $node),
      DomainName                  => $xpc->findvalue('.//cf:DomainName', $node),
      Enabled                     => $xpc->findvalue('.//cf:Enabled') eq 'true' ? 1 : 0,
      DefaultRootObject           => $xpc->findvalue('.//cf:DefaultRootObject') || undef,
      CNAME                       => $xpc->findvalue('.//cf:CNAME') || undef,
      InProgressValidationBatches => $xpc->findvalue('.//cf:InProgressValidationBatches') || undef,
      Comment                     => $xpc->findvalue('.//cf:Comment') || undef,
      CallerReference             => $xpc->findvalue('.//cf:CallerReference') || undef,
      Origin                      => $origin,
      # TODO: Logging, ActiveTrustedSigners.
    );
    return $dist;
  }# end if()
}# end distribution()


sub add_distribution
{
  my ($s, %args) = @_;
  
  my $type = 'CreateDistribution';
  my $response = $s->request( $type, %args )->request();
  my $xpc = $response->xpc;

  if( my ($node) = $xpc->findnodes('.//cf:Distribution') )
  {
    my $origin;
    if( my ($origin_s3) = $xpc->findnodes('.//cf:S3Origin', $node) )
    {
      $origin = AWS::CloudFront::S3Origin->new(
        OriginAccessIdentity  => $xpc->findvalue('.//cf:OriginAccessIdentity', $origin_s3),
        DNSName               => $xpc->findvalue('.//cf:DNSName', $origin_s3),
      );
    }
    elsif( my $origin_custom = $xpc->findnode('.//cf:CustomOrigin', $node) )
    {
    
    }# end if()
    my $dist = AWS::CloudFront::Distribution->new(
      cf                          => $s,
      Id                          => $xpc->findvalue('.//cf:Id', $node),
      Status                      => $xpc->findvalue('.//cf:Status', $node),
      LastModifiedTime            => $xpc->findvalue('.//cf:LastModifiedTime', $node),
      DomainName                  => $xpc->findvalue('.//cf:DomainName', $node),
      Enabled                     => $xpc->findvalue('.//cf:Enabled') eq 'true' ? 1 : 0,
      DefaultRootObject           => $xpc->findvalue('.//cf:DefaultRootObject') || undef,
      CNAME                       => $xpc->findvalue('.//cf:CNAME') || undef,
      InProgressValidationBatches => $xpc->findvalue('.//cf:InProgressValidationBatches') || undef,
      Comment                     => $xpc->findvalue('.//cf:Comment') || undef,
      CallerReference             => $xpc->findvalue('.//cf:CallerReference') || undef,
      Origin                      => $origin,
      # TODO: Logging, ActiveTrustedSigners.
    );
    return $dist;
  }# end if()
}# end add_distribution()


sub distributions
{
  my ($s) = @_;
  
  my $type = 'GetDistributionList';
  my $response = $s->request( $type )->request();
  
  my $xpc = $response->xpc;
  my @dists = ( );
  foreach my $node ( $xpc->findnodes('.//cf:DistributionSummary') )
  {
    my $origin;
    if( my ($origin_s3) = $xpc->findnodes('.//cf:S3Origin', $node) )
    {
      $origin = AWS::CloudFront::S3Origin->new(
        OriginAccessIdentity  => $xpc->findvalue('.//cf:OriginAccessIdentity', $origin_s3),
        DNSName               => $xpc->findvalue('.//cf:DNSName', $origin_s3),
      );
    }
    elsif( my $origin_custom = $xpc->findnode('.//cf:CustomOrigin', $node) )
    {
      # TODO
    }# end if()
    my $dist = AWS::CloudFront::Distribution->new(
      cf                          => $s,
      Id                          => $xpc->findvalue('.//cf:Id', $node),
      Status                      => $xpc->findvalue('.//cf:Status', $node),
      LastModifiedTime            => $xpc->findvalue('.//cf:LastModifiedTime', $node),
      DomainName                  => $xpc->findvalue('.//cf:DomainName', $node),
      Enabled                     => $xpc->findvalue('.//cf:Enabled') eq 'true' ? 1 : 0,
      DefaultRootObject           => $xpc->findvalue('.//cf:DefaultRootObject') || undef,
      CNAME                       => $xpc->findvalue('.//cf:CNAME') || undef,
      InProgressValidationBatches => $xpc->findvalue('.//cf:InProgressValidationBatches') || undef,
      Comment                     => $xpc->findvalue('.//cf:Comment') || undef,
      CallerReference             => $xpc->findvalue('.//cf:CallerReference') || undef,
      Origin                      => $origin,
      # TODO: Logging, ActiveTrustedSigners.
    );
    push @dists, $dist;
  }# end foreach()
  
  return @dists;
}# end distributions()


sub origin_access_identities
{
  my ($s, %args) = @_;
  
  my @out = ( );
  FETCH: {
    my $response = $s->request( 'GetOriginAccessIdentityList', %args )->request();

    my $xpc = $response->xpc;
    foreach my $node ( $xpc->findnodes('.//cf:CloudFrontOriginAccessIdentitySummary') )
    {
      my ($config) = $xpc->findnodes('.//cf:CloudFrontOriginAccessIdentityConfig');
      my $ident = $s->origin_access_identity( $xpc->findvalue('.//cf:Id', $node) );
      push @out, $ident;
    }# end foreach()
    if( $xpc->findvalue('.//cf:IsTruncated') eq 'true' )
    {
      $args{Marker} = $xpc->findvalue('.//cf:NextMarker');
      next FETCH;
    }# end if()
  };
  
  return @out;
}# end origin_access_identities()


sub origin_access_identity
{
  my ($s, $id) = @_;
  
  my $response = $s->request( 'GetOriginAccessIdentity', Id => $id )->request();
  my $xpc = $response->xpc;
  return AWS::CloudFront::OriginAccessIdentity->new(
    Id                => $xpc->findvalue('.//cf:Id'),
    S3CanonicalUserId => $xpc->findvalue('.//cf:S3CanonicalUserId'),
    CallerReference   => $xpc->findvalue('.//cf:CallerReference'),
    Comment           => $xpc->findvalue('.//cf:Comment'),
  );
}# end origin_access_identity()


1;# return true:

=pod

=head1 NAME

AWS::CloudFront - Lightweight interface to Amazon CloudFront CDN

=head1 SYNOPSIS

  # TBD

=head1 DESCRIPTION

CloudFront is the CDN part of Amazon's AWS Cloud environment.

This module aims to wrap their REST API in a nice object-oriented interface.

=head1 PUBLIC PROPERTIES

TBD

=head1 PUBLIC METHODS

TBD

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE AND COPYRIGHT

This software is Free software and may be used and redistributed under the same
terms as any version of perl itself.

Copyright John Drago 2011 all rights reserved.

=cut

