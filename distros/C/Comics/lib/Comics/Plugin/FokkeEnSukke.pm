#! perl

use strict;
use warnings;

package Comics::Plugin::FokkeEnSukke;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name = "Fokke en Sukke";
our $url = "https://www.nrc.nl/fokke-sukke/";

# See TODO in Base.pm.

our $pattern =
  qr{ <meta \s+ property="og:image" \s+
	content=".*/s3(?<url>/static.nrc.nl/images/gn4/stripped/(?<image>.*\.jpg))"
  }x;

# Important: Return the package name!
__PACKAGE__;
