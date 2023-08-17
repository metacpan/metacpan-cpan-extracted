#! perl

use strict;
use warnings;

package Comics::Plugin::Nozzman;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Nozzman";
our $url     = "https://nozzman.nl/persoonlijk-werk";

our $pattern =
  qr{ <div \s+ class="grid__image-wrapper"> \s*
      <img \s+
       src="(?<url>https?://cdn.myportfolio.com/
	   [a-f0-9---]+/
	   (?<image>[a-f0-9---]+_rw_\d+\.\w+)
	   \?h=[0-9a-f]+)"
    }ix;

# Important: Return the package name!
__PACKAGE__;
