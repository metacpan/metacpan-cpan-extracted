use 5.038002;
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'App::ReslirpTunnel',
               VERSION_FROM => 'lib/App/ReslirpTunnel.pm',
               PREREQ_PM => { 'File::XDG' => '1.03',
                              'Log::Any' => '1.717',
                              'Net::OpenSSH' => '0.84',
                              'Path::Tiny' => '0.146',
                              'Data::Validate::Domain' => '0.15',
                              'Data::Validate::IP' => '0.31',
                            },
               ABSTRACT_FROM => 'lib/App/ReslirpTunnel.pm',
               AUTHOR => 'Salvador Fandiño <sfandino@yahoo.com>',
               LICENSE => 'perl',
               EXE_FILES => ['bin/reslirp-tunnel'],
);
