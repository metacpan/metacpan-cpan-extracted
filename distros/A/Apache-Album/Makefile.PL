use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile( 'NAME'	      => 'Apache::Album',
	       'VERSION_FROM' => 'Album.pm', # finds $VERSION
	       'PREREQ_PM'    => { 'Image::Magick' => 1.45, 
				 },
	     );
