#! perl

use strict;
use warnings;

package Comics::Plugin::DoghouseDiaries;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {
    shift->SUPER::register
      ( { name    => "DoghouseDiaries",
	  url     => "http://www.thedoghousediaries.com/",
	  pat     =>
	    qr{ <div \s+ id="imgdiv" .*?> \s+
		<img \s+
		 src='(?<url>dhdcomics/(?<image>.*?\.\w+)) \s* ' \s+
		 title='(?<title>.*?)'> \s+
		 </div>
              }sx,
	} );
}

# Important: Return the package name!
__PACKAGE__;
