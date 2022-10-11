package TestProjectCORS;
use warnings;
use strict;

use Dancer2;
use Dancer2::Plugin::RPC::RESTISH;

set log => $ENV{TEST_DEBUG} ? 'debug' : 'error';

# Register calls directly via POD
restish '/system' => {
    publish     => 'pod',
    arguments   => ['TestProject::SystemCalls'],
    plugin_args => {
        cors_allow_origin => 'http://localhost:8080',
    },
};
restish '/db' => {
    publish     => 'pod',
    arguments   => ['TestProject::ApiCalls'],
    plugin_args => {
        cors_allow_origin => '*',
    }
};

1;

__END__
restish:
    GET  /system/ping
    GET  /system/version
    PUT  /db/person
    POST /db/person/:id
    GET  /db/person/:id

