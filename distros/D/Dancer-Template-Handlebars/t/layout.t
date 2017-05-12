use strict;
use warnings;

use Test::More tests => 1;

{
    package MyApp;

    use lib 't/lib';

    use Dancer ':syntax';

    set views => 't/views';
    set layout => 'layout';

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

    get '/' => sub {
        template 'hello' => {
            you => 'world',
        };
    };

}

use Dancer::Test appdir => 't';

response_content_like '/' => qr/!!! \s+ hello \s there, \s world \s+ !!!/xi, 'basic layout';

