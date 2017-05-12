use strict;
use warnings;

use Test::More tests => 4;

{
    package MyApp;

    use lib 't/lib';

    use Dancer ':syntax';

    set views => 't/views';
    config->{views} = 't/views';

    set logger => 'console';
    set show_errors => 0;
    set traces => 0;

    set engines => {
        handlebars => {
            helpers => [ 'MyHelpers' ],
        },
    };

    set template => 'handlebars';

    get '/string' => sub {
        template \'hello {{ you }}', {
            you => 'world',
        };
    };

    get '/file' => sub {
        template 'hello', {
            you => 'File',
        };
    };

    get '/helper' => sub {
        template 'helper', {
            name => 'Bob',
        };
    };

    get '/helper2' => sub {
        template 'helper2', {
            name => 'Bob',
        };
    };

}

use Dancer::Test appdir => 't';

response_content_is '/string' => 'hello world', 'string ref';

response_content_like '/file' => qr'Hello there, File', 'file';

response_content_like '/helper' => qr'hello BOB', 'helpers';

response_content_like '/helper2' => qr'hello bob', 'helpers';
