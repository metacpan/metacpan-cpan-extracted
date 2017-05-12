package Business::OnlinePayment::MockDie;

use strict;
use warnings;

use base 'Business::OnlinePayment';

sub submit {
    die;
}

1;
