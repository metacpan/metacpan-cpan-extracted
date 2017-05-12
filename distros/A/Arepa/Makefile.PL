use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'                => 'Arepa',
    'VERSION_FROM'        => 'lib/Arepa.pm',
    'ABSTRACT_FROM'       => 'lib/Arepa.pm',
    'AUTHOR'              => 'Esteban Manchado Velázquez <estebanm@opera.com>',
    'PREREQ_PM'           => {'Test::Deep'                 => 0,
                              'DBD::SQLite'                => 0,
                              'File::chmod'                => 0,
                              'Parse::Debian::PackageDesc' => 0,
                              'Config::Tiny'               => 0,
                              'YAML::Syck'                 => 0,
                              'XML::RSS'                   => 0,
                              'Mojolicious'                => 0,
                              'MojoX::Session'             => 0,
                              'HTML::Tree'                 => 0,
                              'Migraine'                   => 0.51,
                              'Test::Class'                => 0,
                              'TheSchwartz'                => 1.10,
                              'Proc::Daemon'               => 0.04},
    'test'                => { TESTS => 't/*.t t/*/*.t' },
);
