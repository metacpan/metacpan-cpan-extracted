use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'Crypt::Unsnoopable',
	      AUTHOR              => q{Ashish Gulhati <crypt-unsnoopable at hash.neo.tc>},
	      VERSION_FROM        => 'lib/Crypt/Unsnoopable.pm',
	      ABSTRACT_FROM       => 'lib/Crypt/Unsnoopable.pm',
              LICENSE             => 'Artistic_2_0',
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'Bytes::Random::Secure' => 0,
			    'Math::Prime::Util' => 0,
			    'Compress::Zlib' => 0,
			    'Persistence::Object::Simple' => 0,
			    'File::HomeDir' => 0,
			    'GD::Barcode::QRcode' => 0
			   },
	      META_MERGE => {
			     "meta-spec" => { version => 2 },
			     prereqs => {
					 runtime => {
						     recommends => {
								    'Wx' => 0,
								   },
						    },
					},
			    },
	      EXE_FILES => [ 'bin/unsnoopable.pl' ],
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Crypt-Unsnoopable-*' },
	     );
