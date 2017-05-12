use 5.008001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Catalyst::Helper::Dojo',
    VERSION_FROM   => 'lib/Catalyst/Helper/Dojo.pm',
    PREREQ_PM      => {
        File::Spec => 0,
        HTML::Dojo => 0,
    },
    ABSTRACT_FROM  => 'lib/Catalyst/Helper/Dojo.pm',
    AUTHOR         => 'Carl Franks <cfranks@cpan.org>',
);
