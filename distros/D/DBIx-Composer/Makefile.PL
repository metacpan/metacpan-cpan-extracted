use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DBIx::Composer',
    VERSION_FROM => 'lib/DBIx/Composer.pm', # finds $VERSION
    AUTHOR       => 'Igor Plisco (soft@plisco.ru)',
    ABSTRACT     => 'Composes and runs SQL statements.',
);
