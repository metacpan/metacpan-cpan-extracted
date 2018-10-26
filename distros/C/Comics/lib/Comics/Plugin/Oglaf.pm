#! perl

package Comics::Plugin::Oglaf;

use parent qw( Comics::Fetcher::Single );

our $VERSION = "1.00";

our $name = "Oglaf";

our $url = "http://www.oglaf.com/";

our $pattern =
  qr{ img \s+ id="strip" \s+
      src="(?<url>http://media.oglaf.com/comic/(?<image>.*?\.\w+))" \s+
      alt="(?<alt>.*?)" \s+
      title="(?<title>.*?)" \s*
    }six;

our $nextpage =
  qr{ <a \s+
       href="(?<url>/.*?/)"> \s*
      <div \s+ id="nx" \s+ class="nav_ro"> \s*
      </div> \s*
      </a>
    }six;

our $nextstory =
  qr{ <a \s+
       href="(?<url>/.*?/)"> \s*
      <div \s+ id="ns" \s+ class="nav_ro"> \s*
      </div> \s*
      </a>
    }six;

our $ondemand = 1;		# NSFW

__PACKAGE__;
