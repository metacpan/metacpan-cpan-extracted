use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'Crypt::RSA::Blind',
	      AUTHOR              => q{Ashish Gulhati <crypt-rsab at hash.neo.tc>},
	      VERSION_FROM        => 'lib/Crypt/RSA/Blind.pm',
	      ABSTRACT_FROM       => 'lib/Crypt/RSA/Blind.pm',
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'Crypt::FDH' => 0,
			    'Crypt::RSA' => 0,
			    'Compress::Zlib' => 0
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Crypt-RSA-Blind-*' },
	     );
