use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Alvis-Bags',
    VERSION_FROM => 'lib/Alvis/URLs.pm', # finds \$VERSION
    AUTHOR       => 'Wray Buntine',
    ABSTRACT     => 'Simple bag generation and control scripts for MPCA for text and links',
    PREREQ_PM    => {HTML::Entities => 0, Encode => 0, Getopt::Long => 0,
		     Pod::Usage => 0, IO::Handle => 0, POSIX => 0,
                     URI => 0, Digest::MD5 => 0,
                    },
    EXE_FILES    => [ 
			'bin/linkRedir',
			'bin/linkTables',
			'bin/linkBags',
			'bin/linkMpca',
		],
);
