#!/usr/bin/env perl

use lib::abs 'lib';
use Dancer::Test;
use Image::Size 'imgsize';
use MyApp;
use Test::More tests => 13;


my @t = (
	{
		n => 'default',
		u => '/crop/50/100',
		t => 'image/jpeg',
		s =>  [ 1421, 1461 ],
		g => '50x100',
	},
	{
		n => 'anchors',
		u => '/crop/50/100/rb',
		t => 'image/jpeg',
		s => [ 1616, 1677 ],
		g => '50x100',
	},
	{
		n => 'shortcut',
		u => '/scrop/50/100',
		t => 'image/jpeg',
		s =>  [ 1421, 1461 ],
		g => '50x100',
	},
);

#
# main
#
for ( @t ) {
	# status
	response_status_is [ GET => $_->{u} ] => 200,
		$_->{n} . ' status';

	# type
	response_headers_include [ GET => $_->{u} ] => ['Content-Type' => $_->{t}],
		$_->{n} . ' type';

	# size
	my $x = do { local $/ = length (dancer_response(GET => $_->{u})->content) };
	ok $x >= $_->{s}[0] && $x <= $_->{s}[1],
		$_->{n} . ' size [' . $x . ']';

	# geometry
	is sprintf( '%dx%d', imgsize \dancer_response(GET => $_->{u})->content ) =>
		$_->{g}, $_->{n} . ' geometry';
}

#
# custom
#
response_status_is
	[ GET => '/resize/50/100/none' ] => 500,
	'invalid anchors status'
;

