package Business::FraudDetect::_Fake;

use vars qw( @ISA $result $fraud_score );

@ISA = qw ( Business::OnlinePayment );

sub _glean_parameters_from_parent {
  my ($self, $parent) = @_;
  $result      = $parent->fraud_detect_faked_result;
  $fraud_score = $parent->fraud_detect_faked_score;
}

sub fraud_score {
  $fraud_score;
}

sub submit {
  my $self = shift;
  $result ? $self->error_message('') : $self->error_message('Planned failure.');
  $self->is_success($result);
}

1;
