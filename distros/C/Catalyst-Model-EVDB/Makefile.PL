use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Catalyst::Model::EVDB',
    AUTHOR        => 'Daniel Westermann-Clark <danieltwc@cpan.org>',
    VERSION_FROM  => 'lib/Catalyst/Model/EVDB.pm',
    ABSTRACT_FROM => 'lib/Catalyst/Model/EVDB.pm',
    PREREQ_PM     => {
        'Catalyst'       => '5.5',
        'Catalyst::Test' => 0,
        'Data::Dumper'   => 0,
        'EVDB::API'      => 0,
        'FindBin'        => 0,
        'NEXT'           => 0,
        'Test::More'     => 0,
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Catalyst-Model-EVDB-* MANIFEST META.yml README' },
);


package MY;

sub postamble {
    return <<"...";
cover::
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test
	cover

readme::
	perldoc -o text -d README \$(NAME)
...
}

1;
