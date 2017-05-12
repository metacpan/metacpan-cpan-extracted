

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Alvis::QueryFilter',
    VERSION_FROM => 'lib/Alvis/QueryFilter.pm', # finds \$VERSION
    AUTHOR       => 'Kimmo Valtonen, Wray Buntine, Vladimir Poroshin',
    ABSTRACT     => 'Alvis query filter for SRU',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Data::Dumper' => 0, 'CQL::Parser' => 0, 'URI::Escape' => 0,
		     'LWP::UserAgent' => 0, 'HTTP::Daemon' => 0, 'HTTP::Status' => 0, 'HTTP::Response' => 0,
                    },
    EXE_FILES    => [ 'bin/run_QF.pl' ],
);
