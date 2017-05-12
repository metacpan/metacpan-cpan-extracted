use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'DBIx::Simple',
    VERSION_FROM  => 'lib/DBIx/Simple.pm',
    PREREQ_PM     => { 'DBI' => '1.21' },
    ABSTRACT_FROM => 'lib/DBIx/Simple.pm',
    AUTHOR        => 'Juerd Waalboer <juerd@cpan.org>'
);
