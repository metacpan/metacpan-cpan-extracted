
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Crypt::Format',
    VERSION_FROM => 'lib/Crypt/Format.pm',                                # finds \$VERSION
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    ABSTRACT     => 'Conversion utilities for encryption applications',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'MIME::Base64' => 0.01,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/FGasper/p5-Crypt-Format.git',
                 web  => 'https://github.com/FGasper/p5-Crypt-Format',
             },
         },
    },
    TEST_REQUIRES => {
        'Test::More' => 1.0,
        'Test::Simple' => 0.44,
        'Test::Exception' => 0.40,
    },
);
