#!/usr/bin/env perl

use lib::abs 'lib';
use Dancer::Test;
use Image::Size 'imgsize';
use MyApp;
use Test::More tests => 4;


response_status_is [ GET => '/original' ] => 200,
	'status';

response_headers_include
	[ GET => '/original' ] => [ 'Content-Type' => 'image/jpeg' ],
	'type';

is do {
	local $/;
	length ( readline dancer_response( GET => '/original' )->content );
} => 57191, 'size';

is sprintf(
	'%dx%d', imgsize \do {
	local $/;
	readline dancer_response( GET => '/original' )->content;
}) => '640x480',
	'geometry'
;

