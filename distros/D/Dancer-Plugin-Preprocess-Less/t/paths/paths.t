use strict;
use warnings;

use Dancer ':syntax';
use Dancer::FileUtils 'read_glob_content';
use Dancer::Test;
use Test::More import => [ '!pass' ];

{
    package TestApp;

    use Dancer ':syntax';

    BEGIN {
        set appdir => path(dirname(__FILE__), 'app');
        set public => path(dirname(__FILE__), 'app', 'public');
        set plugins => {
            'Preprocess::Less' => {
                paths => [ '/', 'css' ]
            }
        };
    }

    use Dancer::Plugin::Preprocess::Less;
}

plan tests => 4;

my $res;

$res = dancer_response(GET => '/foo.css');
like($res->content, qr/width: 2px/,
    'A .less file under root path is processed');

$res = dancer_response(GET => '/css/bar.css');
like($res->content, qr/height: 4px/,
    'A .less file in a selected path is processed');

$res = dancer_response(GET => '/sub/bar.css');
like(read_glob_content($res->content), qr/color: red/,
    'A .less file in a non-selected path is not processed');

$res = dancer_response(GET => '/css/sub/bar.css');
like(read_glob_content($res->content), qr/color: red/,
    'A .less file in a subdir of a selected path is not processed');
