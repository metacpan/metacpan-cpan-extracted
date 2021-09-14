#! perl

use strict;
use warnings;

package Comics::Plugin::SlackWyrm;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.02";

our $name    = "Slack Wyrm";
our $url     = "https://www.joshuawright.net/";

our $pattern =
  qr{ 
       src="(?<url>images/(?<image>picture%20-%20slackwyrm%20[\w%]+\.\w+))\?crc=\d+"
    }x;

# Important: Return the package name!
__PACKAGE__;
