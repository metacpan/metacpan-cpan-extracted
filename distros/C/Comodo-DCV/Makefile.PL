

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Comodo::DCV',
    VERSION_FROM => 'lib/Comodo/DCV.pm', # finds \$VERSION
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    ABSTRACT     => 'DCV logic for COMODO SSL APIs',
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/FGasper/p5-Comodo-DCV.git',
                 web  => 'https://github.com/FGasper/p5-Comodo-DCV',
             },
         },
    },
    TEST_REQUIRES    => {
                     'MIME::Base64' => 0.01,
                     'Test::More' => 0.44,
                    },
);
