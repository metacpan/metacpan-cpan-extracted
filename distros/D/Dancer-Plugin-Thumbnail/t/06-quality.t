#!/usr/bin/env perl

use lib::abs 'lib';
use Dancer::Test;
use Image::Size 'imgsize';
use MyApp;
use Test::More tests => 12;


my @t = (
	{
		n => 'low',
		u => '/quality/50/100/25',
		t => 'image/jpeg',
		s => [ 1002, 1022 ],
		g => '50x38',
	},
	{
		n => 'medium',
		u => '/quality/50/100/70',
		t => 'image/jpeg',
		s => [ 1319, 1339 ],
		g => '50x38',
	},
	{
		n => 'high',
		u => '/quality/50/100/95',
		t => 'image/jpeg',
		s => [ 2265, 2653 ],
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

