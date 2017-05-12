#! perl -w
use strict;
use Test::More tests => 1;

SKIP: {
    if (!eval { require Module::Signature; 1 }) {
	    skip ("Next time around, consider install Module::Signature, ".
		  "so you can verify the integrity of this distribution.", 1);
    }  elsif (! eval { require Socket; Socket::inet_aton('pgp.mit.edu') }) {
	    skip ("Cannot connect to the keyserver", 1);
    }  elsif (! -f "SIGNATURE") {
	    skip ("No SIGNATURE file present", 1);
    } else {
	    ok (Module::Signature::verify() ==
		Module::Signature::SIGNATURE_OK()
			  => "Valid signature" );
    }
}

# arch-tag: 2a8891d9-b5af-450b-a3ba-b2cb8383bda1
