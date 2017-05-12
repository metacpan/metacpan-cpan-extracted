package Example::TransactionSearcher;

use Moo;
use MooX::Options;

use feature qw( say );

use Business::PayPal::API::TransactionSearch;
use DateTime;
use Data::Printer;
use String::CamelCase qw( camelize );

# search options
option amount => (
    is       => 'ro',
    format   => 's',
    required => 0,
    doc      => 'payment amount',
);

option end_date => (
    is       => 'ro',
    format   => 's',
    required => 0,
    doc      => 'end date for search. eg 2005-12-22T08:51:28Z',
);

option start_date => (
    is       => 'ro',
    format   => 's',
    required => 0,
    lazy     => 1,
    doc      => 'start date for search. eg 2005-12-22T08:51:28Z',
    default => sub { DateTime->now->truncate( to => 'day' )->datetime . 'Z' },
);

option payer => (
    is       => 'ro',
    format   => 's',
    required => 0,
    doc      => 'payer email address',
);

option transaction_id => (
    is       => 'ro',
    format   => 's',
    required => 0,
    doc      => 'transaction id',
);

with 'Example::Role::Auth';

sub search {
    my $self = shift;

    my @terms = ( 'amount', 'end_date', 'payer', 'start_date', );

    my %search_terms
        = map { camelize($_) => $self->$_ } grep { $self->$_ } @terms;
    $search_terms{TransactionID} = $self->transaction_id
        if $self->transaction_id;

    say 'Search terms: ';
    p %search_terms;

    my @response = $self->_client->TransactionSearch(%search_terms);
    unless ( ref $response[0] ) {
        my %error = @response;
        p %error;
        die;
    }

    return $response[0];
}

1;
