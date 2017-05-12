use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Model::Xapian',
    AUTHOR              => 'Jonathan Rockway <mramberg@cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/Model/Xapian.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Model/Xapian.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Search::Xapian' => '0.9.2.4',
        'Encode'         => '0',
        'Storable'       => '0',
        'Catalyst'       => '5.30',
        'Data::Page'     => '0',
        'MRO::Compat'    => '0',
		 },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Model-Xapian-*' },
);
