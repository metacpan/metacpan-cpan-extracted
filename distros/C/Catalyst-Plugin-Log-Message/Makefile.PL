use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Catalyst::Plugin::Log::Message',
    'VERSION_FROM' => 'lib/Catalyst/Plugin/Log/Message.pm',
    'PREREQ_PM'    => {
            'Catalyst'      => '5.66',
            'Log::Message'  => '0.01',
            'Test::More'    => '0.62',
        }
);
