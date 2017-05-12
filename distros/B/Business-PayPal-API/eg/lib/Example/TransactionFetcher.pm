package Example::TransactionFetcher;

use Moo;
use MooX::Options;

use Business::PayPal::API::GetTransactionDetails;
use Data::Printer;

option transaction_id => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'transaction id',
);

with 'Example::Role::Auth';

sub find {
    my $self     = shift;
    my %response = $self->_client->GetTransactionDetails(
        TransactionID => $self->transaction_id );

    p %response;
}

1;
