use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'Crypt::EECDH',
	      AUTHOR              => q{Ashish Gulhati <crypt-eecdh at hash.neo.tc>},
	      VERSION_FROM        => 'lib/Crypt/EECDH.pm',
	      ABSTRACT_FROM       => 'lib/Crypt/EECDH.pm',
	      ($ExtUtils::MakeMaker::VERSION >= 6.64
	       ? ('LICENSE'=> 'perl')
	       : ()),
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'Crypt::Curve25519' => 0,
			    'Crypt::Ed25519' => 0,
			    'Crypt::EC_DSA' => 0,
			    'Bytes::Random::Secure' => 0,
			    'Crypt::Rijndael' => 0,
			    'Digest::SHA' => 0
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Crypt-EECDH-*' },
	     );
