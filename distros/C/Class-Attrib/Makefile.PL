use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    META_MERGE		=> {
	resources	=> {
	    repository	=> 'https://github.com/kcodyjr/class-attrib',
	},
    },
    NAME		=> 'Class::Attrib',
    LICENSE		=> 'lgpl_2_1',
    VERSION_FROM	=> 'Attrib.pm', # finds $VERSION
    ABSTRACT_FROM	=> 'Attrib.pm',
    PREREQ_PM		=> {
	'Carp'		=> 0,
	'Class::Multi'	=> 1.02,
	'Storable'	=> 0,
    },
    dist		=> {
        COMPRESS	=> 'gzip',
	SUFFIX		=> 'gz',
    },
    AUTHOR		=> 'Kevin Cody-Little <kcody@cpan.org>',
);
