use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CFDI',
    VERSION_FROM      => 'lib/CFDI.pm', 
    PREREQ_PM         => {}, 
    ABSTRACT_FROM     => 'lib/CFDI.pm',
    AUTHOR            => 'Aldo Montes Zapata <amontes@cpan.org>',
    LICENSE           => 'artistic_2',
);
