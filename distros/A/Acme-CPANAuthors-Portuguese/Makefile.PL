use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::CPANAuthors::Portuguese',
    AUTHOR              => 'Luis Azevedo (Braceta) <braceta@cpan.org>',
    VERSION_FROM        => 'lib/Acme/CPANAuthors/Portuguese.pm',
    ABSTRACT_FROM       => 'lib/Acme/CPANAuthors/Portuguese.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Acme::CPANAuthors::Register'	=> '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-CPANAuthors-Portuguese-*' },
);
