use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Catalyst::Plugin::Server',
    'VERSION_FROM' => 'lib/Catalyst/Plugin/Server.pm',
    'EXE_FILES'    => ['bin/rpc_client'],
    'PREREQ_PM'    => { 'Catalyst'          => '5.66',
                        'RPC::XML'          => '1.35',
                        'RPC::XML::Parser'  => '1.12',
                        'MRO::Compat'       => 0,
			'Clone::Fast'       => 0,
                    }
);
