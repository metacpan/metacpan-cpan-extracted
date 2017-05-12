#!/usr/bin/perl

use strict;
use Test::More tests => 1;

SKIP: {
	if ( -f 'unins000.exe' ) {
		skip("This seems to be the windows installer distribution, ".
			"this cannot be verified as it contains additional files.", 1);
	}
	elsif (!-s 'SIGNATURE') {
		skip("No signature file found", 1);
	}
	elsif (!eval { require Module::Signature; 1 }) {
		skip("Next time around, consider install Module::Signature, ".
			"so you can verify the integrity of this distribution.", 1);
	}
	elsif (!eval { require Socket; Socket::inet_aton('pgp.mit.edu') }) {
		skip("Cannot connect to the keyserver", 1);
	}
	else {
		ok(Module::Signature::verify() == Module::Signature::SIGNATURE_OK()
			=> "Valid signature" );
	}
}

__END__
