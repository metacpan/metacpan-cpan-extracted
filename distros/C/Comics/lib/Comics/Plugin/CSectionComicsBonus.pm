#! perl

use strict;
use warnings;

package Comics::Plugin::CSectionComicsBonus;

use parent qw(Comics::Fetcher::Cascade);

our $VERSION = "1.00";

our $name    = "C-Section Comics";

# C-Section Comics seems to return arbitrary comics.

# our $url     = "http://www.csectioncomics.com/";
# our $pattern =
#   qr{ <div \s+ id="comic"> \s+
#       <img \s+
#        src="(?<url>http://.*?.csectioncomics.com/csectioncomics/
#                    wp-content/uploads/\d+/\d+/
#                    (?<image>.*?\.\w+))" \s+
#        alt="(?<alt>.*?)" \s+
#        title="(?<title>.*?)" \s*
#       />
#     }six;

# Retrieve from the archives page instead.

our $url     = "http://www.csectioncomics.com/";
our @patterns =
  (   qr{ <a \s+
           href="?(?<url>https?://www.csectioncomics.com/archives)"?>
          Comics</a>
        }six,
      qr{ <td \s+
           class="?archive-title"?> \s*
          <a \s+
	   href="?(?<url>https?://www.csectioncomics.com/comics/.*?)"? \s+
           rel="?bookmark"?
        }six,
      qr{ <div \s+ id="?bonus-comic"? \s+ style="?display:none"?> \s*
	  <img \s+
	   src="?(?<url>https?://.*?.csectioncomics.com/csectioncomics/
		       wp-content/uploads/\d+/\d+/
		       (?<image>.*?\.\w+))"? \s+
	   alt="(?<alt>.*?)" \s+
      }six,
   );

# Important: Return the package name!
__PACKAGE__;
