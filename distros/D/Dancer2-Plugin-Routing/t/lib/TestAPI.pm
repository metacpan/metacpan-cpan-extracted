package t::lib::TestAPI;

no warnings 'uninitialized';

use Dancer2;
use Dancer2::Plugin::Routing;

set plugins => {
    'Routing' => {
        template_key => 'routing',
        routes       => {
            main => {
                route   => '/',
                package => 'TestApp',
            },
            api => {
                route   => '/api',
                package => 'TestAPI',
            },
        },
    },
};

set logger => 'capture';
set log    => 'debug';

get '' => sub {
    return root_redirect '/';
};

post '/path' => sub {

    return root_redirect '/';
};

get '/path' => sub {
    return root_redirect '/';
};

1;
