package MY::UpperCase;

use strict;
use warnings;
use Apache2::Filter qw();
use Apache2::Const -compile => qw(OK);

sub handler {
    my $f = shift;
    while ($f->read(my $buf, 1024)) {
        $f->print( uc($buf) );
    }
    return Apache2::Const::OK;
}

1;
