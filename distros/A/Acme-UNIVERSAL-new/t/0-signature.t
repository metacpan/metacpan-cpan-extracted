#!/usr/bin/perl
# $File: //member/autrijus/Module-Signature/t/0-signature.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 1328 $ $DateTime: 2002/10/11 18:56:44 $

use strict;
use Test::More tests => 1;

SKIP: {
    skip( 'No signature!', 1 ) unless -e 'SIGNATURE';
    if (eval { require Module::Signature; 1 }) {
	ok(Module::Signature::verify() == Module::Signature::SIGNATURE_OK()
	    => "Valid signature" );
    }
    else {
	diag("Next time around, consider install Module::Signature,\n".
	     "so you can verify the integrity of this distribution.\n");
	skip("Module::Signature not installed", 1)
    }
}

__END__
