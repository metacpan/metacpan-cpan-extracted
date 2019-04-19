#! perl

use strict;
use warnings;

package Comics::Plugin::GoneIntoRapture;

#### NOTE: Requires OK from Oath/Tumbler.

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Gone into Rapture";
our $url     = "http://goneintorapture.com/";

# Can't get it to work anymore.
our $disabled = 1;

our $pattern =
  qr{ <figure \s+ class="photo-hires-item"> \s+
      <a .*? > \s*
      <img \s+
       src="(?<url>https?://.*?.media.tumblr.com/.*?/
            (?<image>.+?\.\w+))" \s+
       (?: alt|title )=
    }sx;

# Important: Return the package name!
__PACKAGE__;
