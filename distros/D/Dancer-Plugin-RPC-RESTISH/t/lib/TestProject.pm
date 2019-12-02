package TestProject;
use Dancer ':syntax';
use Dancer::Plugin::RPC::RESTISH;

# Register calls directly via POD
restish '/system' => {
    publish   => 'pod',
    arguments => ['TestProject::SystemCalls'],
};
restish '/db' => {
    publish   => 'pod',
    arguments => ['TestProject::ApiCalls'],
};
true;

__END__
restish:
    GET  /system/ping
    GET  /system/version
    PUT  /db/person
    POST /db/person/:id
    GET  /db/person/:id

