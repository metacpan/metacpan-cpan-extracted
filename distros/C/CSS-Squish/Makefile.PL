use 5.008;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'CSS::Squish',
    ABSTRACT_FROM     => 'lib/CSS/Squish.pm',
    VERSION_FROM      => 'lib/CSS/Squish.pm',
    MIN_PERL_VERSION  => 5.008,
    PREREQ_PM         => {
        'File::Spec'        => 0,
        'URI'               => 0,
        'URI::file'         => 0,
        'Scalar::Util'      => 0,
    },
    BUILD_REQUIRES    => {
        'Test::LongString'  => 0,
    },
    AUTHOR            => 'Thomas Sibley <trs@bestpractical.com>',
);

