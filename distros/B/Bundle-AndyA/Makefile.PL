use 5.008006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Bundle::AndyA',
    VERSION_FROM => 'AndyA.pm',
    PREREQ_PM    => {},
    dist         => {
        SUFFIX       => ".gz",
        DIST_DEFAULT => 'all tardist',
        COMPRESS     => "gzip -9f",
        ZIP_FLAGS    => '-pr9'
    },
    ( AUTHOR => 'Andy Armstrong <andy@hexten.net>' )
);
