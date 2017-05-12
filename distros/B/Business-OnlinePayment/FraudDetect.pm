package Business::FraudDetect;



use vars qw / $VERSION @ISA /;

$VERSION = '0.01';
@ISA = qw / Business::OnlinePayment /;

1;

=pod

=head1 NAME

Business::FraudDetect - A cohort to Business::OnlinePayment

=head1 SYNOPSIS

  my %processor_info = ( fraud_detection => 'preCharge',
                         maximum_fraud_score => 500,
                         preCharge_id => '1000000000000001',
                         preCharge_security1 => 'abcdef0123',
                         preCharge_security2 => '3210fedcba',
                        )
  my $transaction = new Business::OnlinePayment($processor, %processor_info);
  $transaction->content(
                        type       => 'Visa',
                        amount     => '49.95',
                        cardnumber => '1234123412341238',
                        expiration => '0100',
                        name       => 'John Q Doe',
                       );
  $transaction->submit();

  if($transaction->is_success()) {
    print "Card processed successfully: ".$transaction->authorization()."\n";
  } else {
    print "Card was rejected: ".$transaction->error_message()."\n";
  }

=head1 DESCRIPTION

This is a module that adds functionality to Business::OnlinePayment.  See L<Business::OnlinePayment>.

The user instantiates a Business::OnlinePayment object per usual, adding in three processor directives

=over 4

=item *  fraud_detection

Which Fraud Detection module to use.

=item *  maximum_fraud_score

FraudDetection drivers are expected to return a numeric "risk" factor, this parameter allows you to set the threshold to reject the transaction based on that risk.  Higher numbers are "riskier" transactions.

=item * other driver-specific parameters.

Consult the specific Fraud Detection module you intend to use for its required parameters.

=back

The $tx->submit() method is overridden to interpose a FraudDetection phase.  A subordinate object is created using the same content as the parent OnlinePayment object, and a I<Fraud Detect> action is run against that subordinate object.  If the resulting fraud score is less than or equal to the maximum_risk parameter, the parent transaction will be allowed to proceed.  Otherwise, a failure state will exist with a suitable error message.

=head1 METHODS

This module provides no new methods.  It does, however override the
submit method to interpose an additional Fraud Detection phase. 

=head1 AUTHORS

Original author: Lawrence Statton <lawrence@cluon.com>

Current maintainer: Ivan Kohler <ivan-bop@420.am> as part of the
Business::OnlinePayment distribution.

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Business::OnlinePayment>, http://perl.business/onlinepayment


=cut
