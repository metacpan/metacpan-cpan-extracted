package CSRFApp::PublishCSRFTicket;

use base qw(CSRFApp::Base);
use strict;
use warnings;

sub index : PublishCSRFID {
    my $self = shift;
    return qq{<form action="" method="post"><input type="hidden" name="rm" value="finish"><input type="submit" value="submit"></form>};
}

sub finish : ProtectCSRF {  
    my $self = shift;
    $self->clear_csrf_id(1);
    return "finish!";
}

1;

