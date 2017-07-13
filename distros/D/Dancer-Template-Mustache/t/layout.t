use strict;
use warnings;

use Test::More tests => 1;

{
    package MyApp;

    use Dancer ':syntax';

    set views => 't/views';
    set layout => 'face';

    set engines => {
        mustache => { 
        },
    };

    set template => 'mustache';

    get '/style/:style' => sub {
        template 'layout' => {
            style => param('style')
        };
    };
}

use Dancer::Test;

response_content_like [ GET => '/style/fu_manchu' ], 
    qr/Manly \s+ fu_manchu \s+ mustache \s+ you \s+ have \s+ there/x, 
    "layout";



