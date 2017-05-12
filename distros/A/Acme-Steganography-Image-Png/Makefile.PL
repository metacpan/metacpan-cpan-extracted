use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Acme::Steganography::Image::Png',
    'VERSION_FROM' => 'Png.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Imager' => 0,
			    'Class::Accessor' => 0,
			    'Test::More' => 0,
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (# ABSTRACT_FROM => 'Png.pm', # retrieve abstract from module
       AUTHOR     => 'Nicholas Clark <nick@ccl4.org>') : ()),
    ((eval $ExtUtils::MakeMaker::VERSION > 6.30) ? (LICENSE => 'perl') : ()),
);
