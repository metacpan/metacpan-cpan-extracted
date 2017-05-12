
print STDERR "Using compatibility macros/routines for Perl 5.004\n"
    if ($] < 5.0045);



use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'installation',
	'DISTNAME'	=> 'Aw',
	'VERSION_FROM'	=> 'lib/Aw.pm', # finds $VERSION
	'DEFINE'	=>
		($] < 5.0045 ? '-DPERL5004_COMPAT -DAWXS_WARNS' : '-DAWXS_WARNS'),
	'PREREQ_PM' 	=> { 'CORBA::LongLong' => 0 },
	dist		=>	{ 
		COMPRESS	=>	"gzip -9f",
		SUFFIX		=>	"gz",
		POSTOP		=>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	AUTHOR		=> "Daniel Yacob <Yacob\@wMUsers.Com>",
	ABSTRACT	=> "Interface to the ActiveWorks Libraries.",
);
