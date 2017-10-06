use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME                => 'App::NoodlePay',
	      AUTHOR              => q{Ashish Gulhati <noodlepay at hash.neo.tc>},
	      VERSION_FROM        => 'lib/App/NoodlePay.pm',
	      ABSTRACT_FROM       => 'lib/App/NoodlePay.pm',
	      LICENSE             => 'Artistic_2_0',
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'Wx' => 0,
			    'GD::Barcode::QRcode' => 0,
			    'Math::Prime::Util' => 0
			   },
	      EXE_FILES => [ 'bin/noodlepay.pl' ],
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'App-NoodlePay-*' },
	     );
