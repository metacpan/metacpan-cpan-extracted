use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer;
use Dancer::Test;

use lib 't/lib';
use TestApp;

setting appdir => setting('appdir') . '/t';

session lang => 'en';
my $res = dancer_response GET => '/';
is $res->{status}, 200, 'check status response';
is $res->{content}, 'Welcome', 'check simple key english';

$res = dancer_response GET => '/no_key';
is $res->{content}, 'goodbye', 'check no key found english';

$res     = dancer_response GET => '/complex_key';
my $path = setting('appdir');
is $res->{content},  "$path not found", 'check complex key english';

session lang => 'fr';
$res = dancer_response GET => '/';
is $res->{content}, 'Bienvenue', 'check simple key french';

$res = dancer_response GET => '/no_key';
is $res->{content}, 'goodbye', 'check no key found french';

$res = dancer_response GET => '/complex_key';
is $res->{content}, "Repertoire $path non trouve", 'check complex key english';


## test language auto-detect when we have no session
## I don't see why the TestApp.pm is having a session (or in other words, why testing "if ( setting('session') ) {" in Wolowitz.pm returns true - at least in my setup)
## diag "--- dropping session";
## what's the right way? (couldn't get it to work in test context):
# session lang => undef;
# setting 'session' => undef;
# session->destroy;
sub todo_tests_not_working_yet {

	session->destroy;
	# two letter language code (dunno if this is RFC compliant, and ever sent by a browser)
	$res = dancer_response( 'GET' => '/', { headers => HTTP::Headers->new('Accept_Language', 'fr') });
	is $res->{content}, 'Bienvenue', 'check Accept-Language parsing';

	session->destroy;
	# example string from Wikipedia List_of_HTTP_header_fields
	$res = dancer_response( 'GET' => '/', { headers => HTTP::Headers->new('Accept_Language', 'en-US') });
	is $res->{content}, 'Welcome', 'check Accept-Language parsing';

	session->destroy;
	# example string from rfc2616-sec14: would mean: "I prefer Danish, but will accept British English and other types of English."
	$res = dancer_response( 'GET' => '/', { headers => HTTP::Headers->new('Accept_Language' => 'da, en-gb;q=0.8, en;q=0.7') });
	is $res->{content}, 'Velkomst', 'check Accept-Language parsing';


	session->destroy;
	# This test will trigger loc() twice withing the same request, so
	# the shortcut in _detect_lang_from_browser is triggered, where we
	# stored a previously detected lang into the request hash.
	# This test isn't actually possible, as we'd have to inspect what's
	# going on in Wolowitz and request(), but the route illustrates the concept
	$res = dancer_response( 'GET' => '/twice_same_request', { headers => HTTP::Headers->new('Accept_Language' => 'da, en-gb;q=0.8, en;q=0.7') });
	is $res->{content}, 'Velkomst Hej', 'check detection shortcut, in no-session environment';
}

## test new feature: being able to pass loc() a language, instead of leaving this to auto-detect
is t::lib::TestApp::loc("welcome",[],'en'), "Welcome", "call loc() with forced language en";
is t::lib::TestApp::loc("welcome",[],'fr'), "Bienvenue", "call loc() with forced language fr";
is t::lib::TestApp::loc("welcome",[],'da'), "Velkomst", "call loc() with forced language da";


done_testing;
