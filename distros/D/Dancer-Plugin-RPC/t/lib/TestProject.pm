package TestProject;
use Dancer ':syntax';
use Dancer::Plugin::RPC::JSONRPC;
use Dancer::Plugin::RPC::XMLRPC;
use Dancer::Plugin::RPC::RESTRPC;

# Register calls directly via POD
xmlrpc '/system' => {
    publish   => 'pod',
    arguments => ['TestProject::SystemCalls'],
};

# Register calls directly via POD
xmlrpc '/api'    => {
    publish   => 'pod',
    arguments => ['TestProject::ApiCalls'],
};

# Register calls via YAML-config
xmlrpc '/config/system' => { publish => 'config' };
xmlrpc '/config/api'    => { publish => 'config' };

# Register calls directly via POD
jsonrpc '/jsonrpc/api' => {
    publish => 'pod',
    arguments => ['TestProject::ApiCalls']
};

# Register calls via YAML-config
jsonrpc '/jsonrpc/admin' => { publish => 'config' };


restrpc '/rest/system' => {
    publish   => 'pod',
    arguments => ['TestProject::SystemCalls'],
};

true;

__END__
xmlrpc:
    /system        system.ping
    /system        system.version
    /api           api.uppercase (argument)
    /config/system system.ping
    /config/system system.version
    /config/api    api.uppercase (argument)

jsonrpc:
    /jsonrpc/api   api.uppercase (argument)
    /jsonrpc/admin ping
    /jsonrpc/admin version
    /jsonrpc/admin uppercase (argument)

restrpc:
    /rest/system/ping
    /rest/system/version

