use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.7 2002/02/09 06:32:03 thomas Exp $
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::Gallery',
    'VERSION_FROM'	=> 'lib/Apache/Gallery.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
 				Image::Info  => 0,
				Image::Size => 0,
				Image::Imlib2 => 1.02,
				Text::Template => 0, 
				URI => 1.23,
				CGI => 3.08,
				Test::More => 0,
				File::Spec => 0
										 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Apache/Gallery.pm', # retrieve abstract from module
       AUTHOR     => 'Michael Legart <michael@legart.dk>') : ()),
);
