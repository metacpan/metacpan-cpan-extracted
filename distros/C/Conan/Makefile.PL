use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Conan',
    VERSION_FROM => 'lib/Conan.pm',
    AUTHOR      => 'Peter Blair <cpan@petermblair.com>',
    ABSTRACT       => 'Building and promoting images a xen cloud',
    PREREQ_PM => {
        'Test::More' => 0.10,
        'File::Rsync' => 0.42,
    },
);


