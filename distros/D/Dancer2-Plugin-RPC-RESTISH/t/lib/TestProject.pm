package TestProject;
use Dancer2;
use Dancer2::Plugin::RPC::RESTISH;

set log => $ENV{TEST_DEBUG} ? 'debug' : 'error';

# Register calls directly via POD
restish '/system' => {
    publish   => 'pod',
    arguments => ['TestProject::SystemCalls'],
};
restish '/db' => {
    publish   => 'pod',
    arguments => ['TestProject::ApiCalls'],
};

1;
__END__
restish:
    GET  /system/ping
    GET  /system/version
    PUT  /db/person
    POST /db/person/:id
    GET  /db/person/:id

