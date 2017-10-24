use ExtUtils::MakeMaker;

require 5.00502;

WriteMakefile(
    NAME                => 'Class::Accessor',
    VERSION_FROM        => 'lib/Class/Accessor.pm',
    AUTHOR              => 'Marty Pauley <marty+perl@martian.org>',
    LICENSE             => 'perl',
    PREREQ_PM           => { base => $] == 5.006 ? 1.02 : 1.01, },
);
