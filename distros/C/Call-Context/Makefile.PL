

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Call::Context',
    VERSION_FROM => 'lib/Call/Context.pm', # finds \$VERSION
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    ABSTRACT     => 'Sanity-check calling context',
    LICENSE      => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/FGasper/p5-Call-Context.git',
                 web  => 'https://github.com/FGasper/p5-Call-Context',
             },
         },
    },
    TEST_REQUIRES    => {
                     'Test::More' => 0.44,
                    },
);
