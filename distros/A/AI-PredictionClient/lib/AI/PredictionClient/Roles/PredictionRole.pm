use strict;
use warnings;
package AI::PredictionClient::Roles::PredictionRole;
$AI::PredictionClient::Roles::PredictionRole::VERSION = '0.05';

# ABSTRACT: Implements the Prediction service interface

use AI::PredictionClient::CPP::PredictionGrpcCpp;
use AI::PredictionClient::Testing::PredictionLoopback;
use JSON ();
use Data::Dumper;
use MIME::Base64 qw( encode_base64 decode_base64 );
use Moo::Role;

has host => (is => 'ro');

has port => (is => 'ro',);

has loopback => (
  is      => 'rw',
  default => 0,
);

has debug_verbose => (
  is      => 'rw',
  default => 0,
);

has perception_client_object => (
  is      => 'lazy',
  builder => 1,
);

sub _build_perception_client_object {
  my $self = $_[0];

  my $server_port = $self->host . ':' . $self->port;
  return $self->loopback
    ? AI::PredictionClient::Testing::PredictionLoopback->new($server_port)
    : AI::PredictionClient::CPP::PredictionGrpcCpp::PredictionClient->new(
    $server_port);
}

has request_ds => (
  is      => 'ro',
  default => sub { { modelSpec => { name => "", signatureName => "" } } },
);

has reply_ds => (
  is      => 'rwp',
  default => sub { {} },
);

sub model_name {
  my ($self, $model_name) = @_;
  $self->request_ds->{"modelSpec"}->{"name"} = $model_name;
  return;
}

sub model_signature {
  my ($self, $model_signature) = @_;
  $self->request_ds->{"modelSpec"}->{"signatureName"} = $model_signature;
  return;
}

has status => (is => 'rwp',);

has status_code => (is => 'rwp',);

has status_message => (is => 'rwp',);

sub serialize_request {
  my $self = shift;

  printf("Debug - Request: %s \n", Dumper(\$self->request_ds))
    if $self->debug_verbose;

  my $json = JSON->new;

  my $request_json = $json->encode($self->request_ds);
  printf("Debug - JSON Request: %s \n", Dumper(\$request_json))
    if $self->debug_verbose;

  return $request_json;
}

sub deserialize_reply {
  my $self              = shift;
  my $serialized_return = shift;

  printf("Debug - JSON Response: %s \n", Dumper(\$serialized_return))
    if $self->debug_verbose;

  my $json = JSON->new;

  my $returned_ds = $json->decode(
    ref($serialized_return) ? $$serialized_return : $serialized_return);
  $self->_set_status($returned_ds->{'Status'});
  $self->_set_status_code($returned_ds->{'StatusCode'});

  my $message_base = $returned_ds->{'StatusMessage'};
  my $message
    = ref($message_base)
    ? decode_base64($message_base->{'base64'}->[0])
    : $message_base;
  $self->_set_status_message($message ? $message : "");

  $self->_set_reply_ds($returned_ds->{'Result'});

  printf("Debug - Response: %s \n", Dumper(\$returned_ds))
    if $self->debug_verbose;

  if ($self->status =~ /^OK/i) {
    return 1;
  }
  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::PredictionClient::Roles::PredictionRole - Implements the Prediction service interface

=head1 VERSION

version 0.05

=head1 AUTHOR

Tom Stall <stall@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Stall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
