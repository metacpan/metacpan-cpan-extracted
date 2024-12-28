#! perl

use strict;
use warnings;

package Comics::Plugin::GeekAndPoke;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.04";

our $name    = "Geek&Poke";
our $url     = "https://geek-and-poke.com/";
our $disabled = 1;		# stopped

our $pattern =
  qr{ <noscript>
      <img \s+
       src="(?<url>https://images.squarespace-cdn.com/
	     content/v1/
		[-_0-9a-z]+/
		[-_0-9a-z]+/
		(?<image>[^./]+\.\w+))"
    }ix;

# Important: Return the package name!
__PACKAGE__;
