package Amazon::S3::Signature::V4;

use strict;
use warnings;

use parent qw{Net::Amazon::Signature::V4};

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my %options;

  if ( !ref $args[0] ) {
    @options{qw{access_key_id secret endpoint service}} = @args;
  }
  else {
    %options = %{ $args[0] };
  }

  my $region = delete $options{region};
  $options{endpoint} //= $region;

  my $self = $class->SUPER::new( \%options );

  return $self;
}

########################################################################
sub region {
########################################################################
  my ( $self, @args ) = @_;

  if (@args) {
    $self->{endpoint} = $args[0];
  }

  return $self->{endpoint};
}

1;
