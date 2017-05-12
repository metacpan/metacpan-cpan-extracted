# -*- perl -*-
use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(NAME          => 'Acme::Study::OS::DateLocales',
	      AUTHOR        => 'Slaven Rezic <srezic@cpan.org>',
	      VERSION_FROM  => 'DateLocales.pm',
	      ABSTRACT_FROM => 'DateLocales.pm',
	      LICENSE       => 'perl',
	      ($ExtUtils::MakeMaker::VERSION >= 6.46
	       ? (META_MERGE => { resources => { repository => 'git://github.com/eserte/acme-study-os-datelocales.git' },
				})
	       : ()
	      ),
	      PREREQ_PM => { 'Data::Dumper' => 0,
			     'File::Spec::Functions' => 0,
			     'POSIX' => 0,
			     'Test::More' => 0,
			   },
	     );
