#! perl

use strict;
use warnings;

package Comics::Plugin::DoodleForFood;

#### NOTE: Requires OK from Oath/Tumbler.

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.03";

our $name    = "Doodle For Food";
our $url     = "https://www.doodleforfood.com/";

# Can't get it to work anymore.
our $disabled = 1;

our $pattern =
  qr{ class="tmblr-full"> \s*
      <img \s+
       src="?(?<url>https?://\d+\.media\.tumblr\.com/
                    [0-9a-f]+/
	            (?<image>tumblr_.+?_1280\.\w+))"? \s+
                    alt="(?<title>.+?)"
    }xs;

# Important: Return the package name!
__PACKAGE__;
