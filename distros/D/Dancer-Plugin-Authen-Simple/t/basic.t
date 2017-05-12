use strict;
use warnings;

use lib 't/lib';

use Test::More;

{
    package WebApp;

    use Dancer;
    use Dancer::Plugin::Authen::Simple;

    set show_errors => 1;

    set plugins => {
        'Authen::Simple' => {
           Fake => { }, 
        },
    };


    get '/auth/:user/:password' => sub {
        return authen->authenticate( param('user'), param('password') );
    };

    1;

}

use Dancer::Test apps => 'WebApp';

response_content_is '/auth/foo/bar' => 0, "not authenticated";
response_content_is '/auth/root/god' => 1, "authenticated";

done_testing;
