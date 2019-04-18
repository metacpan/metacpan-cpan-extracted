#! perl

use strict;
use warnings;

package Comics::Plugin::GeekAndPoke;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Geek&Poke";
our $url     = "http://geek-and-poke.com/";
our $pattern =
  qr{ <noscript>
      <img \s+
       src="(?<url>https://static1.squarespace.com/static/
             [0-9a-f]+/t/[0-9a-f]+/
             (?<image>[0-9a-f]+)/)" \s+
       alt="(?<alt>.*?)" \s*
      />
    }x;

# Important: Return the package name!
__PACKAGE__;
