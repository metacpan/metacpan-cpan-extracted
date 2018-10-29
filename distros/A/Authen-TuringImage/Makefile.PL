use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
	      NAME                => 'Authen::TuringImage',
	      AUTHOR              => q{Ashish Gulhati <authen-ti at hash.neo.tc>},
	      VERSION_FROM        => 'lib/Authen/TuringImage.pm',
	      ABSTRACT_FROM       => 'lib/Authen/TuringImage.pm',
	      PL_FILES            => {},
	      BUILD_REQUIRES      => {
				      'File::ShareDir::Install' => 0,
				     },
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'GD' => 0,
			    'Bytes::Random::Secure' => 0,
			    'File::Share' => 0,
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Authen-TuringImage-*' },
	     );

package MY;

use File::ShareDir::Install 'postamble';
