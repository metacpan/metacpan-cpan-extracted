use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'Crypt::EC_DSA',
	      AUTHOR              => q{Ashish Gulhati <crypt-ecdsa at hash.neo.tc>},
	      VERSION_FROM        => 'lib/Crypt/EC_DSA.pm',
	      ABSTRACT_FROM       => 'lib/Crypt/EC_DSA.pm',
	      ($ExtUtils::MakeMaker::VERSION >= 6.64
	       ? ('LICENSE'=> 'artistic_2')
	       : ()),
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'Bytes::Random::Secure', => 0,
			    'Math::EllipticCurve::Prime', => 0,
			    'Digest::SHA', => 0
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Crypt-EC_DSA-*' },
	     );
