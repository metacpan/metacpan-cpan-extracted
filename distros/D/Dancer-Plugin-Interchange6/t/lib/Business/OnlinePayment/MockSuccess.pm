package Business::OnlinePayment::MockSuccess;

use warnings;
use strict;

use base 'Business::OnlinePayment';

our $auth_id      = 0;
our $order_number = 1000;

sub submit {
    my $self = shift;
    $self->is_success(1);
    $self->authorization( ++$auth_id );
    $self->order_number( ++$order_number );
}

1;
