package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst;

extends 'Catalyst';

__PACKAGE__->config->{'Model::SMS'} = {
    driver => 'Test',
    args   => { username => 'matlads', password => 'matlads' }
};

__PACKAGE__->setup;

1;
