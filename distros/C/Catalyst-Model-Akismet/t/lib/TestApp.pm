package # hide from PAUSE
    TestApp;

use strict;
use warnings;

use Catalyst;

__PACKAGE__->config(
    name        => 'TestApp',
    'Model::Akismet' => {
        key     => 'fake key',
        url => 'http://fake_url',
    },
);

__PACKAGE__->setup;


1;
