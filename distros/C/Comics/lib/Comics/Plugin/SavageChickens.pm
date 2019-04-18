#! perl

use strict;
use warnings;

package Comics::Plugin::SavageChickens;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Savage Chickens";
our $url     = "https://www.savagechickens.com/";
our $pattern =
	    qr{ <div \s+ class="entry_content"> \s*
		<p> \s*
		<img \s+
		 src="(?<url>https?://www.savagechickens.com/
		        wp-content/uploads/
		       (?<image>.*?\.\w+))" \s+
		 alt="(?<alt>.*?)" \s+
		 width="\d+" \s+ height="\d+" \s*
		 /> \s* </p>
	      }sx;

# Important: Return the package name!
__PACKAGE__;
