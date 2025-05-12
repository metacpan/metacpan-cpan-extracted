use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Contract::Declare',
    VERSION_FROM => 'lib/Contract/Declare.pm',
    ABSTRACT     => 'Simple contract system for Perl interfaces',
    AUTHOR       => 'Alexander Ponomarev <shootnix@gmail.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Role::Tiny'    => '0',
        'Exporter'      => '0',
        'Scalar::Util'  => '0',
        'Carp'          => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    MIN_PERL_VERSION => '5.14.0',
);