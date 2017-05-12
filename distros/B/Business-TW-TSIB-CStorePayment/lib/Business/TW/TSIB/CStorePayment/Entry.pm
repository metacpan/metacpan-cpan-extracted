package Business::TW::TSIB::CStorePayment::Entry;
use strict;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw/
                debit_date
                paid_date
                payment_id
                amount
                due
                collection_agent
                payee_account/
);

sub ar_id {
    my $self = shift;
    return int( substr( $self->payment_id , 4 , 12 ) );
}

1;

