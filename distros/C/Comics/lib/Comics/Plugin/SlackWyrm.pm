#! perl

use strict;
use warnings;

package Comics::Plugin::SlackWyrm;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Slack Wyrm";
our $url     = "http://www.joshuawright.net/";

our $pattern =
  qr{ 
       src="(?<url>images/(?<image>(?:\d+|picture)%20-%20slack(?:%20)?wyrm%20-%20[\w%]+\.\w+))\?crc=\d+"
    }x;

# Important: Return the package name!
__PACKAGE__;
