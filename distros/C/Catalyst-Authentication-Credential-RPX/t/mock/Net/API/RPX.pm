package    #NOINDEX
  Net::API::RPX;

# $Id:$
use strict;
use warnings;
use Moose;
use namespace::autoclean;

has 'api_key'  => ( isa => 'Str', required => 1,                                is => 'rw', );
has 'ua'       => ( isa => 'Str', default  => 'Test::MockObject',               is => 'rw', );
has 'base_url' => ( isa => 'Str', default  => 'http://example.com/net/api/rpx', is => 'rw', );

our $RESPONSES = {
  'A' => {
    profile => {
      identifier        => 'http://oid.example.org/persona',
      displayName       => 'Person A',
      providerName      => 'Example.org',
      url               => 'http://oid.example.org/persona',
      preferredUsername => 'A',
    }
  },
  'B' => {
    err => {
      msg  => 'Data not found',
      code => 2,
    },
    stat => 'fail',
  },
};

sub auth_info {
  my ( $self, $conf ) = @_;
  my $token  = $conf->{'token'};
  return $RESPONSES->{ $token };
}

sub map {
  my ( $self, $conf ) = @_;
  die "Not Implemented";
}

sub unmap {
  my ( $self, $conf ) = @_;
  die "Not Implemented";
}

sub mappings {
  my ( $self, $conf ) = @_;
  die "Not Implemented";
}

1;

