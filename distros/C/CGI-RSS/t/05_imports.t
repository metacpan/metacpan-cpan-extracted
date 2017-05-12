# vi:fdm=marker fdl=0 syntax=perl:

use strict;
use Test;
use CGI::RSS 'rss';
use Date::Manip;

plan tests => 4;

ok( eval {           rss("blah") }, "<rss>blah</rss>" ); ok( not $@ );
ok( eval { CGI::RSS::rss("blah") }, "<rss>blah</rss>" ); ok( not $@ );
