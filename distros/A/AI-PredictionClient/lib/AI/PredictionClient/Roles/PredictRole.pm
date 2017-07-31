use strict;
use warnings;
package AI::PredictionClient::Roles::PredictRole;
$AI::PredictionClient::Roles::PredictRole::VERSION = '0.05';
# ABSTRACT: Implements the Predict service specific interface

use AI::PredictionClient::Classes::SimpleTensor;

use Moo::Role;

requires 'request_ds', 'reply_ds';

sub inputs {
  my ($self, $inputs_href) = @_;

  my $inputs_converted_href;

  foreach my $inkey (keys %$inputs_href) {
    $inputs_converted_href->{$inkey} = $inputs_href->{$inkey}->tensor_ds;
  }

  $self->request_ds->{"inputs"} = $inputs_converted_href;

  return;
}

sub callPredict {
  my $self = shift;

  my $request_ref = $self->serialize_request();

  my $result_ref = $self->perception_client_object->callPredict($request_ref);

  return $self->deserialize_reply($result_ref);
}

sub outputs {
  my $self = shift;

  my $predict_outputs_ref = $self->reply_ds->{outputs};

  my $tensorsout_href;

  foreach my $outkey (keys %$predict_outputs_ref) {
    $tensorsout_href->{$outkey} = AI::PredictionClient::Classes::SimpleTensor->new(
      $predict_outputs_ref->{$outkey});
  }

  return $tensorsout_href;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::PredictionClient::Roles::PredictRole - Implements the Predict service specific interface

=head1 VERSION

version 0.05

=head1 AUTHOR

Tom Stall <stall@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Stall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
