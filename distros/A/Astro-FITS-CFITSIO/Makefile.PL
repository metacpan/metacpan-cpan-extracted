use strict;
use warnings;

use Alien::Base::Wrapper 'WriteMakefile';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
        alien_requires => { 'Alien::CFITSIO' => '4.3.0' },
        NAME         => 'Astro::FITS::CFITSIO',
        VERSION_FROM => 'CFITSIO.pm',             # finds $VERSION
        OBJECT       => 'CFITSIO.o util.o',
        LICENSE      => 'perl_5',
        TEST_REQUIRES => { 'Test2::V0' => 0 },
        clean        => { FILES => "testprog.fit testprog/testprog.fit testprog/testprog.lis" },
        META_MERGE   => {
            'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    url => 'https://github.com/pratzlaff/Astro-FITS-CFITSIO.git',
                    web => 'https://github.com/pratzlaff/Astro-FITS-CFITSIO',
                },
            },
        },
);
