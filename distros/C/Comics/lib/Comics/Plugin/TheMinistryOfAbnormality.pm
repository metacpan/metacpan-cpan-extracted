#! perl

use strict;
use warnings;

package Comics::Plugin::TheMinistryOfAbnormality;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "The Ministry of Abnormality";
our $url     = "http://www.theministryofabnormality.com/";

# CHANGED BEYOND REPAIR
our $disabled = 1;

our $pattern =
	    qr{ <div \s+
		 class="entry-thumb"> \s+
		<a \s+
		 href="http://www.theministryofabnormality.com/\?p=\d+" \s+
		 title="(?<title>.*?)" \s*
		> \s*
		<img \s+
		 width="\d+" \s+ height="\d+" \s+
		 src="(?<url>http://www.theministryofabnormality.com/
		        wp-content/uploads/\d+/\d+/
			(?<image>.*?\.\w+))" \s+
		 class=".*?" \s+ alt=".*?"
	      }six;


# Important: Return the package name!
__PACKAGE__;
