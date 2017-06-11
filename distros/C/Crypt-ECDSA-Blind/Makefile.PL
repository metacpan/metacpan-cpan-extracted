use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'Crypt::ECDSA::Blind',
	      AUTHOR              => q{Ashish Gulhati <crypt-ecdsab at hash.neo.tc>},
	      VERSION_FROM        => 'lib/Crypt/ECDSA/Blind.pm',
	      ABSTRACT_FROM       => 'lib/Crypt/ECDSA/Blind.pm',
	      ($ExtUtils::MakeMaker::VERSION >= 6.64
	       ? ('LICENSE'=> 'artistic_2')
	       : ()),
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'DBI', => 0,
			    'DBD::SQLite', => 1.54,
			    'Bytes::Random::Secure', => 0,
			    'Math::EllipticCurve::Prime', => 0.003,
			    'Digest::SHA', => 5.95
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Crypt-ECDSA-Blind-*' },
	     );
