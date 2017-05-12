use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME         => 'API::PleskExpand',
    AUTHOR       => 'NRG <pavel.odintsov@googlemail.com>',
    LICENSE      => 'perl',
    ABSTRACT     => 'API::PleskExpand - OOP interface to the Plesk Expand XML API',
    VERSION_FROM => 'lib/API/PleskExpand.pm',
    PREREQ_PM    => {
                        'API::Plesk'         => '1.06', # parent module
                        'Carp'               => '0',
                        'Data::Dumper'       => '0',
                        'Getopt::Long'       => '0',
                        'HTTP::Request'      => '0',
                        'LWP::UserAgent'     => '0',
                        'Test::More'         => '0',
                        'Test::LongString'   => '0',
                        'URI'                => '0',
                    },
    INSTALLDIRS  => 'site',
    EXE_FILES    => [],
    PL_FILES     => {}
);

