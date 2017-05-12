package TestApp;

use strict;
use warnings;

use Catalyst::Runtime '5.7008';

use Catalyst qw/Config::Multi/;

our $VERSION = '0.01';

__PACKAGE__->config(
    'Plugin::Config::Multi' => { 
        dir => __PACKAGE__->path_to('./../conf'), 
        prefix => 'web',
        app_name => 'testapp',
    },
);

#__PACKAGE__->setup;

1;
