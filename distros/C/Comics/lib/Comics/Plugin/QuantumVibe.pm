#! perl

use strict;
use warnings;

package Comics::Plugin::QuantumVibe;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Quantum Vibe",
	  url     => "http://www.quantumvibe.com",
	  pat	  =>
	    qr{ Strip \s+ \d+ \s+ of \s+ Quantum \s+ Vibe" \s+
		src="(?<url>/disppageV?[34]\?story=qv\&file=/simages/qv/
		  (?<image>[^"]+.jpg))"
	      }x,
	 } );
}

# Important: Return the package name!
__PACKAGE__;
