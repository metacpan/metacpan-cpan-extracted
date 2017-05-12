use lib::abs 'lib';
use Dancer::Test;
use MyApp;
use Test::More tests => 2;
use Data::Dumper;

response_status_is 
	[ GET => '/empty.gif' ] =>  200,
	'found';

response_status_is
	[ GET => '/x' ] => 404,
	'not found';