

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Catalyst::Model::Memcached',
    VERSION_FROM => 'lib/Catalyst/Model/Memcached.pm', # finds \$VERSION
    AUTHOR       => 'Denis Pokataev (catone@cpan.org)',
    ABSTRACT     => 'Wrapper for memcached using Catalyst models approach',
	LICENSE      => 'perl',
    PREREQ_PM    => {
		             'Catalyst::Runtime' => 5.8,
		             'Cache::Memcached::Fast' => 0.17,
                     'Test::More' => 0.44,
                    },
);
