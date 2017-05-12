package # hide from PAUSE
    TestApp;

use strict;
use warnings;

use Catalyst;

__PACKAGE__->config(
    name        => 'TestApp',
    'Model::S3' => {
        aws_access_key_id     => 'fake key',
        aws_secret_access_key => 'fake secret'
    },
);

__PACKAGE__->setup;


1;
