package TimeChannel;

#==============================================================================
#
#         FILE:  TimeChannel.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  28/06/12 00:53:28 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

use Asyncore;
use base qw( Asyncore::Dispatcher );

use DateTime;

sub handle_write {
    my $self = shift;
    
    my $time = sprintf("Time is %s\n", DateTime->now());
    $self->send($time); # send is a keyboard ...
    $self->close();
}

1;

__END__
