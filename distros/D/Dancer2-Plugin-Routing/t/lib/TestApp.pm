package t::lib::TestApp;

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
            admin => '/api',
        },
    },
};

set logger => 'capture';
set log    => 'debug';

get ''                    => sub { template 'index' };
get '/path'               => sub { root_redirect '/' };
get '/routing_for'        => sub { routing_for };
get '/routing_for/:route' => sub { template 'vars', { var => routing_for( route_parameters->get('route') ) } };
get '/package_for/:route' => sub { template 'vars', { var => package_for( route_parameters->get('route') ) } };
get '/package_for'        => sub { package_for };
get '/packages'           => sub { scalar keys %{ packages() } };

post '/path' => sub { root_redirect '/' };

1;
