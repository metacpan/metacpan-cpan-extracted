package AWS::Networks;
  use Moose;
  use JSON;
  use HTTP::Tiny;
  use DateTime;

  our $VERSION = '0.01';

  has url => (
    is => 'ro', 
    isa => 'Str|Undef', 
    default => 'https://ip-ranges.amazonaws.com/ip-ranges.json'
  );

  has netinfo => (
    is => 'ro',
    isa => 'HashRef',
    default => sub {
      my $self = shift;
      die "Can't get some properties from derived results" if (not $self->url);
      my $response = HTTP::Tiny->new->get($self->url);
      die "Error downloading URL" unless ($response->{ success });
      return decode_json($response->{ content });
    },
    lazy => 1,
  );

  has sync_token => (
    is => 'ro',
    isa => 'DateTime',
    default => sub {
      return DateTime->from_epoch( epoch => shift->netinfo->{ syncToken } );
    },
    lazy => 1,
  );

  has networks => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {
      return shift->netinfo->{ prefixes };
    },
    lazy => 1,
  );

  has regions => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {
      my ($self) = @_;
      my $regions = {};
      map { $regions->{ $_->{ region } } = 1 } @{ $self->networks };
      return [ keys %$regions ];
    },
    lazy => 1,
  );

  sub by_region {
    my ($self, $region) = @_;
    return AWS::Networks->new(
      url => undef,
      sync_token => $self->sync_token,
      networks => [ grep { $_->{ region } eq $region } @{ $self->networks }  ]
    );
  }

  has services => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {
      my ($self) = @_;
      my $services = {};
      map { $services->{ $_->{ service } } = 1 } @{ $self->networks };
      return [ keys %$services ];
    },
    lazy => 1,
  );

  sub by_service {
    my ($self, $service) = @_;
    return AWS::Networks->new(
      url => undef,
      sync_token => $self->sync_token,
      networks => [ grep { $_->{ service } eq $service } @{ $self->networks }  ]
    );
  }

  has cidrs => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {
      my ($self) = @_;
      return [ map { $_->{ ip_prefix } } @{ $self->networks } ];
    },
    lazy => 1,
  );

1;

#################### main pod documentation begin ###################

=head1 NAME

AWS::Networks - Parse and query official AWS network ranges

=head1 SYNOPSIS

  use AWS::Networks;

  my $nets = AWS::Networks->new();

  say $nets->sync_token->iso8601;

  foreach my $cidr (@{ $nets->cidrs }){
    say $cidr
  }

=head1 DESCRIPTION

This module parses the official public IP network information published by Amazon Web Services at https://ip-ranges.amazonaws.com/ip-ranges.json

Please read and understand the information can be found at http://docs.aws.amazon.com/general/latest/gr/aws-ip-ranges.html to make sense of the data retured by this module.

=head1 USAGE

Instance an object, and use it to filter information of interest to you with the attributes and methods provided.

=head1 METHODS

=head2 new([ url => 'http....' ])

Standard Moose constructor. Can specify a custom URL to download a document that follows the same schema

=head2 url

Returns the URL from which the information was retrieved. Returns undef on filtered datasets

=head2 sync_token

Returns a DateTime object created from the current timestamp of the syncToken reported from the service

=head2 networks

Returns an ArrayRef with HashRefs following the following structure: 

{ ip_prefix => '0.0.0.0/0', region => '...', service => '...' } 

The keys and values in the HashRefs are the ones returned by the Network service

service can be one of: AMAZON | EC2 | CLOUDFRONT | ROUTE53 | ROUTE53_HEALTHCHECKS, but expect
new values to appear

region can be one of: ap-northeast-1 | ap-southeast-1 | ap-southeast-2 | cn-north-1 | eu-central-1 | eu-west-1 | sa-east-1 | us-east-1 | us-gov-west-1 | us-west-1 | us-west-2 | GLOBAL, but expect new values to appear

=head2 services

Returns an ArrayRef of the different services present in the current dataset

=head2 regions

Returns an ArrayRef of the different regions present in the current dataset

=head2 cidrs

Returns an ArrayRef with the CIDR blocks in the dataset

=head2 by_region($region)

Returns a new AWS::Networks object with the data filtered to only the objects in the
specified region

=head2 by_service($service)

Returns a new AWS::Networks object with the data filtered to only the services specified

=cut

=head1 CONTRIBUTE

The source code is located here: https://github.com/pplu/aws-networks

=head2 SEE ALSO

The dist is bundled with a couple of sample scripts in bin that play around with
the information returned by this module, these scripts try to determine the number
of IP addresses that AWS has, and given an IP address, if it pertains to AWS, and 
what service.

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com
    http://www.pplusdomain.net

=head1 COPYRIGHT

Copyright (c) 2014 by Jose Luis Martinez Torres

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
