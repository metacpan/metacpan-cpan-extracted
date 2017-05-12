#!perl
use Test::More tests => 3;
# obviously the tests that come with this module sucks, but oh well..
BEGIN
{
	use_ok("DateTime::Util::Astro::Common");
	use_ok("DateTime::Util::Astro::Moon");
	use_ok("DateTime::Util::Astro::Sun");
}
