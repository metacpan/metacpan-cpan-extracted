#!perl -w

use strict;
use warnings;
use Test::Most;

eval 'use Test::CGI::Untaint';

if($@) {
        plan skip_all => 'Test::CGI::Untaint required for testing extraction handler';
} else {
        plan tests => 8;

        use_ok('CGI::Untaint::Facebook');

        is_extractable('http://www.facebook.com/rockvillebb', 'https://www.facebook.com/rockvillebb', 'Facebook');
        is_extractable('https://www.facebook.com/rockvillebb', 'https://www.facebook.com/rockvillebb', 'Facebook');
        is_extractable('www.facebook.com/rockvillebb', 'https://www.facebook.com/rockvillebb', 'Facebook');
        is_extractable('voicetimemoney', 'https://www.facebook.com/voicetimemoney', 'Facebook');
        is_extractable(' voicetimemoney  ', 'https://www.facebook.com/voicetimemoney', 'Facebook');
        unextractable('http://www.example.com/foo', 'Facebook');
        unextractable('http://www.facebook.com/fhvhvhj0vfj90', 'Facebook');
}
