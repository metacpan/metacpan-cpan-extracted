use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Copy::From::Git',
    VERSION_FROM => 'lib/Copy/From/Git.pm',
    AUTHOR       => 'Peter Blair (pblair@tucows.com)',
    ABSTRACT     => 'Pull upstream source into package directory',
    PREREQ_PM    => {
                    },
);
