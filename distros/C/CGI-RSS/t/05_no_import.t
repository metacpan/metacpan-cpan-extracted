# vi:fdm=marker fdl=0 syntax=perl:

use strict;
use Test;
use CGI::RSS ();
use Date::Manip;

plan tests => 4;

ok( eval {           rss("blah") }, undef             ); ok( not not $@ );
ok( eval { CGI::RSS::rss("blah") }, "<rss>blah</rss>" ); ok(     not $@ );
