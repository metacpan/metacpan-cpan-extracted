use 5.008007;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Bundle::Ovid',
    VERSION_FROM => 'Ovid.pm',
    PREREQ_PM    => {},
    dist         => {
        SUFFIX       => ".gz",
        DIST_DEFAULT => 'all tardist',
        COMPRESS     => "gzip -9f",
        ZIP_FLAGS    => '-pr9'
    },
    ( AUTHOR => 'Curtis Poe <curtispoe@local>' )
);
