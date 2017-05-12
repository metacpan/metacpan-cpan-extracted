

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Danga::Socket::Redis',
    VERSION_FROM => 'lib/Danga/Socket/Redis.pm', # finds \$VERSION
    AUTHOR       => 'Martin Redmond (@martinredmond)',
    ABSTRACT     => 'An asynchronous redis client.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Danga::Socket::Callback' => 0.01200,
                    },
);
