use lib::abs 'lib';
use Dancer::Test;
use MyApp;
use Test::More tests => 2;

response_headers_include
	[ GET => '/empty.gif' ] => [ 'Content-Type' => 'image/gif' ],
	'type';

response_headers_include
	[ GET => '/empty.gif' ] => [ 'Content-Disposition' => 'inline; filename="empty.gif"' ],
	'disposition';

