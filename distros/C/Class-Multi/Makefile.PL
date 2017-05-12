use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    META_MERGE		=> {
    	resources	=> {
	    repository	=> 'https://github.com/kcodyjr/class-multi',
	},
    },
    NAME		=> 'Class::Multi',
    LICENSE		=> 'lgpl_2_1',
    VERSION_FROM	=> 'Multi.pm', # finds $VERSION
    ABSTRACT_FROM	=> 'Multi.pm',
    PREREQ_PM		=> {
    	Carp		=> 0,
	Exporter	=> 0,
    },
    dist		=> {
        COMPRESS	=> 'gzip',
	SUFFIX		=> 'gz',
    },
    AUTHOR		=> 'Kevin Cody-Little <kcody@cpan.org>',
);
