use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Class::XML::Parser',
    VERSION_FROM    => 'lib/Class/XML/Parser.pm',
    ABSTRACT_FROM   => 'lib/Class/XML/Parser.pm',
    AUTHOR          => 'Mark Morgan <makk384@gmail.com>',
    PREREQ_PM       => {
        'XML::Parser'   => 0,
        'Carp'		=> 0,
    },
);
