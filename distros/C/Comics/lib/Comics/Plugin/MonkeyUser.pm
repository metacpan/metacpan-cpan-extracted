#! perl

use strict;
use warnings;

package Comics::Plugin::MonkeyUser;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Monkey User";
our $url     = "https://www.monkeyuser.com/";

our $pattern =
  qr{ <img \s+
       src="?(?<url>https?://www.monkeyuser.com/
	assets/images/\d+/
	(?<image>.+\.\w+))"? \s+
        alt="(?<alt>.*?)" \s+
        title="(?<title>.*?)" \s*
    }x;

# Important: Return the package name!
__PACKAGE__;
