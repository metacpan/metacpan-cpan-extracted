#! perl

package Comics::Plugin::NickScipio;

use parent qw( Comics::Fetcher::Single );

our $name = "Nick Scipio Picture of the Day";

our $url = "http://www.nickscipio.com/pod/";

our $ondemand = 1;

our $pattern =
  qr{ <img \s+
       class="alignnone \s+ size-large .*?" \s+
       src="(?<url>http://www.nickscipio.com/pod/media/
                   \d+/\d+/
		   (?<image>.*?\.\w+))" \s+
       alt="(?<alt>.*?)" \s+
       width="\d+" \s+ height="\d+"
    }six;

our $VERSION = "1.00";

__PACKAGE__;
