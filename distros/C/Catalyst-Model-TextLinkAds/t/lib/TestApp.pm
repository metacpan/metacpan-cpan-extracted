package TestApp;

use strict;
use warnings;

use Catalyst;

__PACKAGE__->config(
    name                 => 'TestApp',
    'Model::TextLinkAds' => {
        cache  => 0, # disable caching
        tmpdir => 'foobar',
    }
);

__PACKAGE__->setup;


1;
