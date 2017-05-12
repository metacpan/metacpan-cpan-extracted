#   $Id: 00-signature.t 49 2014-05-02 11:30:14Z adam $

use Test::More;
use strict;

BEGIN {

    if ( $ENV{SKIP_SIGNATURE_TEST} ) {
        plan( skip_all => 'Signature test skipped. Unset $ENV{SKIP_SIGNATURE_TEST} to activate test.' );
    }

    eval ' use Test::Signature; ';

    if ( $@ ) {
        plan( skip_all => 'Test::Signature not installed.' );
    }
    else {
        plan( tests => 1 );
    }
}
signature_ok();

