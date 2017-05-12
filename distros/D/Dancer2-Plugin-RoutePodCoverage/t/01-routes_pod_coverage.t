use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;
use Dancer2;

use t::lib::MyApp::Routes;
use t::lib::MyApp::Routes2;

use Dancer2::Plugin::RoutePodCoverage;


## test all packages
my $data_struct = {'t::lib::MyApp::Routes' => {
                    routes => [
                        'post /',
                        'get /'
                    ],
                    undocumented_routes => [
                        'post /'
                    ],
                    has_pod => 1
                    },
                    't::lib::MyApp::Routes2' => {
                    routes => [
                        'post /',
                        'get /'
                    ],
                    undocumented_routes => [
                        'post /',
                        'get /'
                    ],
                    has_pod => 1
                    }
                   };

is_deeply(routes_pod_coverage(),$data_struct, 'route_pod_coverege');


### test t::lib::MyApp::Routes
my $data_struct_1 = {'t::lib::MyApp::Routes' => {
                    routes => [
                        'post /',
                        'get /'
                    ],
                    undocumented_routes => [
                        'post /'
                    ],
                    has_pod => 1
                    }
                   };

packages_to_cover(['t::lib::MyApp::Routes']);
is_deeply(routes_pod_coverage(),$data_struct_1, 'route_pod_coverege');


### test t::lib::MyApp::Routes2
my $data_struct_2 = {'t::lib::MyApp::Routes2' => {
                    routes => [
                        'post /',
                        'get /'
                    ],
                    undocumented_routes => [
                        'post /',
                        'get /'
                    ],
                    has_pod => 1
                    }
                   };

packages_to_cover(['t::lib::MyApp::Routes2']);
is_deeply(routes_pod_coverage(),$data_struct_2, 'route_pod_coverege');

