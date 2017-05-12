package Business::OnlinePayment::MockFail;

use strict;
use warnings;

use base 'Business::OnlinePayment';

sub submit {
    my $self = shift;
    $self->is_success(0);
    $self->failure_status('declined');
    $self->error_message('invalid cvc');
}

1;
