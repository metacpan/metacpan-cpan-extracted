package TestProjectCORS;
use Dancer ':syntax';
use Dancer::Plugin::RPC::RESTISH;

# Register calls directly via POD
restish '/system' => {
    publish           => 'pod',
    arguments         => ['TestProject::SystemCalls'],
    cors_allow_origin => 'http://localhost:8080',
};
restish '/db' => {
    publish           => 'pod',
    arguments         => ['TestProject::ApiCalls'],
    cors_allow_origin => '*',
};
true;

__END__
restish:
    GET  /system/ping
    GET  /system/version
    PUT  /db/person
    POST /db/person/:id
    GET  /db/person/:id

