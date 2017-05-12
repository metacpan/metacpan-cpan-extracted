use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Acme::Opish',
    'VERSION_FROM' => 'lib/Acme/Opish.pm',
    'PREREQ_PM'    => {
        'Test::More' => 0,
        'Carp' => 0,
        'File::Basename' => 0,
    },
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Acme/Opish.pm',
          AUTHOR         => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
