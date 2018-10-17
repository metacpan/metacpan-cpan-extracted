use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'Crypt::EC_DSA',
	      AUTHOR              => q{Ashish Gulhati <crypt-ecdsa at hash.neo.tc>},
	      VERSION_FROM        => 'lib/Crypt/EC_DSA.pm',
	      ABSTRACT_FROM       => 'lib/Crypt/EC_DSA.pm',
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'Bytes::Random::Secure', => 0,
			    'Math::EllipticCurve::Prime', => 0.003,
			    'Digest::SHA', => 5.95
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Crypt-EC_DSA-*' },
	     );
