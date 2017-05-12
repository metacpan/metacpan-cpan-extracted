use ExtUtils::MakeMaker;
use 5.008003;

WriteMakefile(
    NAME         => 'Class::EHierarchy',
    AUTHOR       => 'Arthur Corliss <corliss@digitalmages.com>',
    ABSTRACT     => 'Base class for hierarchally ordered objects',
    VERSION_FROM => 'lib/Class/EHierarchy.pm',
    PREREQ_PM    => {}, (
        $ExtUtils::MakeMaker::VERSION ge '6.30_00' ? ( LICENSE => 'perl' )
        : ()
        ), (
        $ExtUtils::MakeMaker::VERSION ge '6.48'
        ? ( MIN_PERL_VERSION => 5.008003 )
        : ()
        ),
    dist => {
        COMPRESS  => 'gzip',
        SUFFIX    => '.gz',
        CI        => 'cvs ci',
        RCS_LABEL => 'cvs tag -c -F $(NAME_SYM)-$(VERSION_SYM)',
        },
        );

exit 0;
