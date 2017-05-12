package 
    TestApp;

use strict;
use warnings;

use Catalyst;

__PACKAGE__->config(
    name => 'TestApp',
    
    'Model::Amazon' => {
        token => 'fake key',
    },
);

__PACKAGE__->setup;

1;
