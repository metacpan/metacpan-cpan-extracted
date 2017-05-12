package Business::OnlinePayment::MockPopup;

use warnings;
use strict;

use base 'Business::OnlinePayment::MockSuccess';

sub popup_url {
    return "http://localhost/payment_popup";
}

1;
