use strict;
use Test;

BEGIN { plan tests => 1 }

use CGI::pWiki;
use vars qw($pWiki);
$pWiki = new CGI::pWiki;

ok(1);
