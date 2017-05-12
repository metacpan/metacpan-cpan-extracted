require 5.8.4;

use ExtUtils::MakeMaker;

WriteMakefile(
  'PL_FILES' => {},
	'NAME'            => 'Data::Scroller',
 	'INSTALLDIRS' 		=> 'site',
  'VERSION_FROM'    => 'lib/Data/Scroller.pm',
 	'PREREQ_PM'				=> {
										 	'Test::More' => '0',
											'Test::Exception' => '0'
	}
);

