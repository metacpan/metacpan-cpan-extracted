use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'Crypt::FDH',
	      AUTHOR              => q{Ashish Gulhati <crypt-fdh at hash.neo.tc>},
	      VERSION_FROM        => 'lib/Crypt/FDH.pm',
	      ABSTRACT_FROM       => 'lib/Crypt/FDH.pm',
	      ($ExtUtils::MakeMaker::VERSION >= 6.64
	       ? ('LICENSE'=> 'artistic_2')
	       : ()),
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'Digest::SHA' => 0,
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Crypt-FDH-*' },
	     );
