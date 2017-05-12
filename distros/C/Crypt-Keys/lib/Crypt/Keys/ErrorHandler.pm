# $Id: ErrorHandler.pm,v 1.1.1.1 2001/07/10 22:26:08 btrott Exp $

package Crypt::Keys::ErrorHandler;
use strict;

use vars qw( $ERROR );

sub new    { bless {}, shift }
sub error  {
    if (ref($_[0])) {
        $_[0]->{_errstr} = $_[1];
    } else {
        $ERROR = $_[1];
    }
    return;
 }
sub errstr { ref($_[0]) ? $_[0]->{_errstr} : $ERROR }

1;
