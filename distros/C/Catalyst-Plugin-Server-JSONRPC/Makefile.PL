use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Catalyst::Plugin::Server::JSONRPC',
    'VERSION_FROM' => 'lib/Catalyst/Plugin/Server/JSONRPC.pm',
    'EXE_FILES'    => ['bin/jsonrpc_client'],
    'LICENSE'      => 'perl',
    'PREREQ_PM'    => {
        'Catalyst'                 => '5.66',
        'JSON::RPC::Common'        => '0.03',
        'JSON'                     => '2.0',
        'Catalyst::Plugin::Server' => '0.01',
        'MRO::Compat'              => 0,
    }
);
