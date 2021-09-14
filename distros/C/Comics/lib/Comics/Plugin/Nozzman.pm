#! perl

use strict;
use warnings;

package Comics::Plugin::Nozzman;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Nozzman";
our $url     = "https://nozzman.nl/persoonlijk-werk";

our $pattern =
  qr{ <meta \s+ property="og:image" \s+
       content="(?<url>https://pro2-bar-s3-cdn-cf1.myportfolio.com/
		[-_0-9a-z]+/
		(?<image>[^./]+\.\w+))(?:"|\?)
    }ix;

# Important: Return the package name!
__PACKAGE__;
