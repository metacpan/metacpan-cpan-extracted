package # hide from PAUSE
    TestApp;

use strict;
use warnings;

use Catalyst;

__PACKAGE__->config(
    name        => 'TestApp',
    'Model::Filemaker' => {
        host  => 'somehost',
        user  => 'someuser',
        pass  => 'somepass',
        db    => 'somedb'

    },
);

__PACKAGE__->setup;


1;
