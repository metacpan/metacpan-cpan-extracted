package Test::MockUserAgent;

use strict;
use warnings;

use base qw/ Test::MockObject /;

use HTTP::Response;

BEGIN { Test::MockObject->fake_module( 'LWP::UserAgent' ); }

sub new {
  my ( $class ) = @_;

  my $self = $class->SUPER::new();
  $self->fake_new( 'LWP::UserAgent' );
  $self->mock( get => sub { my ( $self ) = @_; $self->{_response} } );

  return $self;
}

sub _response {
  my ( $self, $code, $content ) = @_;

  my $response = HTTP::Response->new( $code );
  $response->content( $content );
  $response->message( 'Fake HTTP Response' );

  $self->{_response} = $response;
}

1;
