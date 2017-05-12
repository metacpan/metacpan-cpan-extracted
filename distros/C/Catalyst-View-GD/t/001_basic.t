#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use File::Spec;

use lib (File::Spec->catdir($FindBin::Bin, 'lib'));

use Test::More tests => 7;

use Test::Image::GD;
use Catalyst::Test 'GDTestApp';

BEGIN {
    use_ok('Catalyst::View::GD');
}

my $TEST_IMAGE_DIR = File::Spec->catdir($FindBin::Bin, 'images');

sub test_image { File::Spec->catfile($TEST_IMAGE_DIR, shift) }

{
    my $response = request('http://localhost/test_one');
    
    ok(defined $response, '... got the response successfully');
    ok($response->is_success, '... response is a success');
    is($response->code, 200, '... response code is 200');
    is_deeply(
    [ $response->content_type ], 
    [ 'image/gif' ], 
    '... the response content type is image/gif');

    my $img = GD::Image->newFromGifData($response->content) || diag "Cannot create new image from data";
    isa_ok($img, 'GD::Image');
    
    cmp_image($img, test_image('test_one.gif'), '... our image matched the control');
}


