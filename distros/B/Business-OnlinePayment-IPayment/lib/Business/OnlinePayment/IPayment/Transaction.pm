package Business::OnlinePayment::IPayment::Transaction;


use 5.010001;
use strict;
use warnings;
use utf8;
use Scalar::Util qw/looks_like_number/;

=encoding utf8

=head1 NAME

Business::OnlinePayment::IPayment::Transaction - Simple object to hold the transaction request

=head1 SYNOPSIS

  $IPayment_object->transaction(transactionType => 'auth',
                                trxAmount       => 5000, # 50 €
                                trxCurrency     => 'EUR',
                                invoiceText     => "Thanks!",
                                trxUserComment  => "Hello!",
                                paymentType     => "cc",
                                shopper_id      => int(rand(5000)),
                                options => {
                                  fromIp => '99.99.99.99',
                                  checkDoubleTrx => 1,
                                  errorLang      => 'en',
                                  # and possibly others, see doc wsdl
                                 });
                      


=cut

use Moo;

=head3 TransactionData

This class holds the data of a single transaction. Given that the
values are all related and shouldn't change over its lifetime, it's
everything read-only.


=over 4

=item trxCurrency

Currency in which the payment is processed. There are all known
three-letter ISO Currency codes allowed. A list of known currency
codes, see L<https://ipayment.de/> under B<Technik>. E.g C<EUR>

CGI Name: C<trx_currency>

Note that the processing of payments in the currency must be agreed
with your payment provider.


Default to C<EUR> in this implementation.

=cut

has trxCurrency => (is => 'ro',
                    default => sub { return 'EUR'},
                    isa => sub {
                        die "Only one argument for trxCurrency" unless @_ == 1;
                        die "Wrong currency" unless $_[0] =~ m/^[A-Z]{3}$/s;
                    });


=item trxAmount

Amount to be debited, in the B<smallest currency unit>, for Example
cents. B<Decimal points> or other characters except numbers are 
B<not allowed>.

CGI Name: C<trx_amount>

=cut

has trxAmount => (is => 'ro',
                  default => sub { return 0 },
                  isa => sub {
                      die "Not a number" unless looks_like_number($_[0]);
                      my $num = $_[0];
                      die "<$num> is not an integer\n"
                        unless $num =~ m/^[1-9][0-9]*$/s;
                  });


=item shopper_id

This parameter allows you to specify a unique ID for an order process.
Under this Shopper ID is saved to the associated transaction in order
ipayment system. The Shopper ID must be unique only if the extended
examination of the IDs Avoidance of double use transactions.

=cut

has shopper_id => (is => 'ro');

=item invoiceText

=cut

has invoiceText => (is => 'ro');

=item trxUserComment

=cut

has trxUserComment => (is => 'ro');

=item recurringData

=cut

has recurringData => (is => 'ro');

=item installmentData

=cut

has installmentData => (is => 'ro');


=item transactionData

Return the hashref with the transaction data details

=cut



sub transactionData {
    my $self = shift;
    my %trx = (
               trxAmount       => $self->trxAmount,
               trxCurrency     => $self->trxCurrency,
               shopperId       => $self->shopper_id,
               );
    if ($self->invoiceText) {
        $trx{invoiceText} = $self->invoiceText;
    }
    if ($self->trxUserComment) {
        $trx{trxUserComment} = $self->trxUserComment;
    }
    if ($self->recurringData) {
        $trx{recurringData} = $self->recurringData;
    }
    if ($self->installmentData) {
        $trx{installmentData} = $self->installmentData;
    }
    return \%trx;
}


=item transactionType

The transaction type, choosen from the types below. It defaults to C<auth>

  preauth
  auth
  base_check
  check_save
  grefund_cap

CGI Name: C<trx_typ>

=cut

has transactionType => (is => 'ro',
                        default => sub { return "auth" },
                        isa => sub {
                            my %avail = (
                                         preauth => 1,
                                         auth => 1,
                                         base_check => 1,
                                         check_save => 1,
                                         grefund_cap => 1,
                                        );
                            my $type = $_[0];
                            die "Missing transaction type\n" unless $type;
                            die "Only one arg is supported\n" unless @_ == 1;
                            die "$type not valid\n" unless $avail{$type};
                        }
                       );

=item paymentType

The payment type, choosen from the types below. It defaults to C<cc> 

  cc
  elv
  pp

CGI Name: C<trx_paymenttyp>

=back

=cut

has paymentType => (is => 'ro',
                    default => sub { return "cc" },
                    isa => sub {
                        my %avail = (
                                     pp => 1,
                                     cc => 1,
                                     elv => 1,
                                    );
                        my $type = $_[0];
                        die "Missing payment type\n" unless $type;
                        die "Only one arg is supported\n" unless @_ == 1;
                        die "Invalid payment type $type\n" unless $avail{$type};
                    });



=head3 options

Additional options for the SOAP request, as a hashref. These options are
quite advanced, so we don't do any additional checking ourselves,
delegating them to the SOAP compiler.

=cut


has options => (is => 'ro',
                isa => sub { die "options should be a hash\n"
                               unless (ref$_[0]) eq 'HASH' });


=head2 Additional transaction information

=head3 addr_info

Hashref to hold additional information, notably the information about
the cardholder.

=cut

has addr_info => (is => 'ro',
                  default => sub { return {} },
                  isa => sub { die "options should be a hash\n"
                                 unless (ref$_[0]) eq 'HASH' });


1;
