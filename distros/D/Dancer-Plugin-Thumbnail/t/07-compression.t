#!/usr/bin/env perl

use lib::abs 'lib';
use Dancer::Test;
use Image::Size 'imgsize';
use MyApp;
use Test::More tests => 16;


my @t = (
	{
		n => 'none',
		u => '/compression/50/100/0',
		t => 'image/png',
		s => [ 5796, 5830 ],
		g => '50x38',
	},
	{
		n => 'low',
		u => '/compression/50/100/1',
		t => 'image/png',
		s => [ 4457, 4503 ],
		g => '50x38',
	},
	{
		n => 'medium',
		u => '/compression/50/100/5',
		t => 'image/png',
		s => [ 4402, 4450 ],
		g => '50x38',
	},
	{
		n => 'high',
		u => '/compression/50/100/9',
		t => 'image/png',
		s => [ 4401, 4449 ],
		g => '50x38',
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

