#
#===============================================================================
#
#         FILE:  cookie.t
#
#  DESCRIPTION:  Test of cookie parsing
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  20/05/14 16:12:33
#
#  Updates:
#    25/08/2014 Now tests get_ordered_keys and print_data.
#===============================================================================

use strict;
use warnings;

use Test::More tests => 264;                      # last test to print

use lib './lib';

BEGIN { use_ok ('CGI::Lite') }

# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     ='/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'there.is.no.try.com';
$ENV{QUERY_STRING}    = '';

my $cgi               = CGI::Lite->new ();
my $cookies           = $cgi->parse_cookies;
is ($cgi->is_error, 0, 'Cookie parse: no cookies, no error');
is ($cookies, undef, 'Cookie parse: no cookies');

$ENV{HTTP_COOKIE}     = 'foo=bar; baz=quux';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
my $testname          = 'simple';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 2, "Cookie count ($testname)");
ok (exists $cookies->{foo}, "First cookie name ($testname)");
is ($cookies->{foo}, 'bar', "First cookie value ($testname)");
ok (exists $cookies->{baz}, "Second cookie name ($testname)");
is ($cookies->{baz}, 'quux', "Second cookie value ($testname)");

# And again but with a hash
$cgi                  = CGI::Lite->new ();
$testname             = 'simple, return hash';
my %cookies           = $cgi->parse_cookies;
is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %cookies, 2, "Cookie count ($testname)");
ok (exists $cookies{foo}, "First cookie name ($testname)");
is ($cookies{foo}, 'bar', "First cookie value ($testname)");
ok (exists $cookies{baz}, "Second cookie name ($testname)");
is ($cookies{baz}, 'quux', "Second cookie value ($testname)");



$ENV{HTTP_COOKIE}     = ' foo=bar ; baz = quux ';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'extra space';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 2, "Cookie count ($testname)");
ok (exists $cookies->{foo}, "First cookie name ($testname)");
is ($cookies->{foo}, 'bar', "First cookie value ($testname)");
ok (exists $cookies->{baz}, "Second cookie name ($testname)");
is ($cookies->{baz}, 'quux', "Second cookie value ($testname)");

$ENV{HTTP_COOKIE}     = 'foo=bar;baz=quux';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'zero space';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 2, "Cookie count ($testname)");
ok (exists $cookies->{foo}, "First cookie name ($testname)");
is ($cookies->{foo}, 'bar', "First cookie value ($testname)");
ok (exists $cookies->{baz}, "Second cookie name ($testname)");
is ($cookies->{baz}, 'quux', "Second cookie value ($testname)");

$ENV{HTTP_COOKIE}     = '%20foo%20=%20bar%20;b%20a%20z=qu%20ux';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'interstitial space';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 2, "Cookie count ($testname)");
ok (exists $cookies->{' foo '}, "First cookie name ($testname)");
is ($cookies->{' foo '}, ' bar ', "First cookie value ($testname)");
ok (exists $cookies->{'b a z'}, "Second cookie name ($testname)");
is ($cookies->{'b a z'}, 'qu ux', "Second cookie value ($testname)");

my $ref = [];
$ref = $cgi->get_ordered_keys;
is_deeply ($ref, [' foo ', 'b a z'], 
	'get_ordered_keys arrayref for cookie data');
my @ref = $cgi->get_ordered_keys;
is_deeply (\@ref, [' foo ', 'b a z'], 
	'get_ordered_keys array for cookie data');


SKIP: {
	skip "No file created for stdout", 2 unless open my $tmp, '>', 'tmpout';
	select $tmp;
	$cgi->print_data;
	close $tmp;
	open $tmp, '<', 'tmpout';
	chomp (my $printed = <$tmp>);
	is ($printed, q# foo  =  bar #, 'print_data first cookie');
	chomp ($printed = <$tmp>);
	is ($printed, q#b a z = qu ux#, 'print_data second cookie');
	close $tmp and unlink 'tmpout';
}

# Other url-escaped chars here

for my $special (33 .. 47, 58 .. 64, 91 .. 96, 123 .. 126) {
	$ENV{HTTP_COOKIE}     = sprintf 'a=%%%X;%%%X=1', $special, $special;
	$cgi                  = CGI::Lite->new ();
	$cookies              = $cgi->parse_cookies;
	$testname             = "Special value ($ENV{HTTP_COOKIE})";
	is ($cgi->is_error, 0, "Cookie parse ($testname)");
	is (scalar keys %$cookies, 2, "Cookie count ($testname)");
	ok (exists $cookies->{'a'}, "First cookie name ($testname)");
	is ($cookies->{'a'}, chr($special), "First cookie value ($testname)");
	ok (exists $cookies->{chr($special)}, "Second cookie name ($testname)");
	is ($cookies->{chr($special)}, 1, "Second cookie value ($testname)");
}

$ENV{HTTP_COOKIE}     = '=bar';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'Missing key';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 1, "Cookie count ($testname)");
ok (exists $cookies->{''}, "First cookie name ($testname)");
is ($cookies->{''}, 'bar', "First cookie value ($testname)");

# Bad cookies!

$ENV{HTTP_COOKIE}     = 'f;o;o=b;a;r';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'Extra semicolons';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 4, "Cookie count ($testname)");
ok (exists $cookies->{'o'}, "First cookie name ($testname)");
is (ref $cookies->{'o'}, 'ARRAY', "First cookie ref ($testname)");
is ($cookies->{'o'}->[0], '', "First cookie first elem ($testname)");
is ($cookies->{'o'}->[1], 'b', "First cookie second elem ($testname)");

$ENV{HTTP_COOKIE}     = 'foo==bar';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'Extra equals';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 1, "Cookie count ($testname)");
ok (exists $cookies->{'foo'}, "First cookie name ($testname)");
is ($cookies->{'foo'}, '=bar', "First cookie value ($testname)");

# Need to decide how strict the cookie validation should be. If strict,
# then these tests could be used. Leaving it lax for now.
# See eg. http://bugs.python.org/issue2193
#
#for my $char (split (//, '()<>@:\"/[]?={} ')) {
#
#	$ENV{HTTP_COOKIE}     = "f${char}o=bar";
#	$cgi                  = CGI::Lite->new ();
#	$cookies              = $cgi->parse_cookies;
#	$testname             = qq#Bad key char: "$char"#;
#
#	is ($cgi->is_error, 1, "Cookie parse ($testname)");
#	is (scalar keys %$cookies, 0, "Cookie count ($testname)");
#
#	$ENV{HTTP_COOKIE}     = "foo=b${char}r";
#	$cgi                  = CGI::Lite->new ();
#	$cookies              = $cgi->parse_cookies;
#	$testname             = qq#Bad value char: "$char"#;
#
#	is ($cgi->is_error, 1, "Cookie parse ($testname)");
#	is (scalar keys %$cookies, 0, "Cookie count ($testname)");
#
#}
#
# What about multiple cookies with the same name?
# cookie o is actually an arrayref, which is neat, but does it match the
# RFC?
#ok (exists $cookies->{'b a z'}, "Second cookie name ($testname)");
#is ($cookies->{'b a z'}, 'qu ux', "Second cookie value ($testname)");

$ENV{HTTP_COOKIE}     = 'foo=bar;foo=baz;foo=quux';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'triple value';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 1, "Cookie count ($testname)");
ok (exists $cookies->{foo}, "First cookie name ($testname)");
is ($cookies->{foo}->[0], 'bar', "First cookie value ($testname)");
is ($cookies->{foo}->[1], 'baz', "First cookie value ($testname)");
is ($cookies->{foo}->[2], 'quux', "First cookie value ($testname)");


$cgi                  = CGI::Lite->new ();
is ($cgi->force_unique_cookies(), 0, "force_unique_cookies undef arg");
is ($cgi->force_unique_cookies('foo'), 0, "force_unique_cookies string arg");
is ($cgi->force_unique_cookies(100), 0, "force_unique_cookies arg > 3");
is ($cgi->force_unique_cookies(1), 1, "force_unique_cookies arg == 1");
$cookies              = $cgi->parse_cookies;
$testname             = 'unique, take first';
is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 1, "Cookie count ($testname)");
ok (exists $cookies->{foo}, "Cookie name ($testname)");
is ($cookies->{foo}, 'bar', "Cookie value ($testname)");

$cgi                  = CGI::Lite->new ();
is ($cgi->force_unique_cookies(2), 2, "force_unique_cookies arg == 2");
$cookies              = $cgi->parse_cookies;
$testname             = 'unique, take last';
is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 1, "Cookie count ($testname)");
ok (exists $cookies->{foo}, "Cookie name ($testname)");
is ($cookies->{foo}, 'quux', "Cookie value ($testname)");

$cgi                  = CGI::Lite->new ();
is ($cgi->force_unique_cookies(3), 3, "force_unique_cookies arg == 3");
$cookies              = $cgi->parse_cookies;
$testname             = 'unique, raise error';
is ($cgi->is_error, 1, "Cookie parse ($testname)");

