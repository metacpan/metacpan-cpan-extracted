#!perl
#
# $Id: /svn/DateTime-Event-Klingon/tags/VERSION_1_0_1/t/00-signature.t 323 2008-04-01T06:37:25.246199Z jaldhar  $
#
use warnings;
use strict;
use Test::More tests => 1;

SKIP: {
    if ( !eval { require Module::Signature; 1 } ) {
        skip(
            'Next time around, consider install Module::Signature, '
                . 'so you can verify the integrity of this distribution.',
            1
        );
    }
    elsif ( !eval { require Socket; Socket::inet_aton('wwwkeys.pgp.net') } ) {
        skip( 'Cannot connect to the keyserver', 1 );
    }
    else {
        ok( Module::Signature::verify()
                == Module::Signature::SIGNATURE_OK() => 'Valid signature' );
    }
}
